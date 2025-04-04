# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorsForm, type: :model do
  subject(:form) { described_class.new(resource: resource, params: params, user: current_user) }

  let(:resource) { build(:work) }
  let(:params) { {} }
  let(:current_user) { build(:user) }

  describe 'initialization' do
    context 'with no params' do
      its(:edit_users) { is_expected.to be_empty }
      its(:edit_groups) { is_expected.to be_empty }
    end

    context 'with a list of values' do
      let(:params) do
        {
          edit_users: ['abc123'],
          edit_groups: ['groupName']
        }
      end

      its(:edit_users) { is_expected.to eq(['abc123']) }
      its(:edit_groups) { is_expected.to eq(['groupName']) }
    end

    context 'with blank values' do
      let(:params) do
        {
          edit_users: ['abc123', ''],
          edit_groups: ['groupName', '']
        }
      end

      its(:edit_users) { is_expected.to eq(['abc123']) }
      its(:edit_groups) { is_expected.to eq(['groupName']) }
    end

    context 'when the resource has existing users and grous' do
      let(:user) { build(:user) }
      let(:group) { build(:group) }
      let(:resource) { build(:work, edit_users: [user], edit_groups: [group]) }

      its(:edit_users) { is_expected.to contain_exactly(user.uid) }
      its(:edit_groups) { is_expected.to contain_exactly(group.name) }
    end
  end

  describe '#resource' do
    its(:resource) { is_expected.to eq resource }
  end

  describe '#group_options' do
    context 'when the user has NO additional groups' do
      its(:group_options) { is_expected.to be_empty }
    end

    context 'when the user has additional groups' do
      let(:current_user) { build(:user, groups: User.default_groups + [group]) }
      let(:group) { build(:group) }

      its(:group_options) { is_expected.to contain_exactly(group.name) }
    end
  end

  describe '#save' do
    context 'when the user exists' do
      let(:params) { { 'edit_users' => [user.access_id], 'notify_editors' => notify_editors } }
      let(:user) { create(:user) }
      let(:notify_editors) { false }

      before { allow(UserRegistrationService).to receive(:call).with(uid: user.access_id).and_return(user) }

      [:work, :collection].each do |resource_type|
        context "when given a #{resource_type}" do
          let(:resource) { build(resource_type) }

          it 'adds the user as an editor' do
            expect(resource.edit_users).to be_empty
            form.save
            resource.reload
            expect(resource.edit_users).to contain_exactly(user)
          end
        end

        context 'when the resource already has some edit users' do
          let(:existing_user) { create(:user) }
          let(:resource) { create(resource_type, edit_users: [existing_user]) }
          let(:mailer_spy) { instance_spy('MailerSpy') }

          before do
            allow(ActorMailer).to receive(:with).and_return(mailer_spy)
          end

          context 'when the send notification email is checked' do
            let(:notify_editors) { true }

            it 'sends an email to any new users' do
              form.save

              expect(ActorMailer).to have_received(:with).with(actor: user.actor, resource: resource)
              expect(ActorMailer).not_to have_received(:with).with(actor: existing_user.actor, resource: resource)

              expect(mailer_spy).to have_received(:added_as_editor)
              expect(mailer_spy).to have_received(:deliver_later)
            end
          end

          context 'when the send notification email is not checked' do
            it 'does not send an email to any new users' do
              form.save

              expect(ActorMailer).not_to have_received(:with)
            end
          end
        end
      end
    end

    context 'when the user does NOT exist' do
      let(:params) { { 'edit_users' => [access_id] } }
      let(:access_id) { build(:user).uid }

      before do
        allow(UserRegistrationService).to receive(:call).with(uid: access_id).and_return(nil)
        allow(ActorMailer).to receive(:with)
      end

      it 'does not add the user and reports an error' do
        expect(resource.edit_users).to be_empty
        form.save
        expect(resource.edit_users).to be_empty
        expect(form.errors.full_messages).to contain_exactly(
          'Edit users ' +
          I18n.t!('activemodel.errors.models.editors_form.attributes.edit_users.not_found', access_id: access_id)
        )
      end

      it 'does not send any emails' do
        form.save
        expect(ActorMailer).not_to have_received(:with)
      end
    end

    context 'when the service returns URI::InvalidURIError' do
      let(:params) { { 'edit_users' => [access_id] } }
      let(:access_id) { build(:user).email }

      before do
        allow(UserRegistrationService).to receive(:call).with(uid: access_id).and_raise(URI::InvalidURIError)
        allow(ActorMailer).to receive(:with)
      end

      it 'does not add the user and reports an error' do
        expect(resource.edit_users).to be_empty
        form.save
        expect(resource.edit_users).to be_empty
        expect(form.errors.full_messages).to contain_exactly(
          'Edit users ' +
          I18n.t!('activemodel.errors.models.editors_form.attributes.edit_users.unexpected', access_id: access_id)
        )
      end

      it 'does not send any emails' do
        form.save
        expect(ActorMailer).not_to have_received(:with)
      end
    end

    context 'when the service returns an unexpected error' do
      let(:params) { { 'edit_users' => [access_id] } }
      let(:access_id) { build(:user).email }

      before do
        allow(UserRegistrationService).to receive(:call).with(uid: access_id).and_raise(StandardError, 'oops!')
        allow(ActorMailer).to receive(:with)
      end

      it 'raises the error' do
        expect { form.save }.to raise_error(StandardError, 'oops!')
      end

      it 'does not send any emails' do
        begin
          form.save
        rescue StandardError
        end

        expect(ActorMailer).not_to have_received(:with)
      end
    end

    context 'when adding a group' do
      let(:params) { { 'edit_groups' => [group.name] } }
      let(:group) { create(:group) }

      it 'adds the group as an editor' do
        expect(resource.edit_groups).to be_empty
        form.save
        resource.reload
        expect(resource.edit_groups).to contain_exactly(group)
      end
    end

    context 'when the group does NOT exist' do
      let(:params) { { 'edit_groups' => ['missing-group'] } }

      it 'adds the group as an editor' do
        expect(resource.edit_groups).to be_empty
        form.save
        resource.reload
        expect(resource.edit_groups).to be_empty
      end
    end
  end
end
