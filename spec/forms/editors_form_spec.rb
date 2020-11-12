# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorsForm, type: :model do
  subject(:form) { described_class.new(work: work, params: params, user: current_user) }

  let(:work) { build(:work) }
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

    context 'when the work has existing users and grous' do
      let(:user) { build(:user) }
      let(:group) { build(:group) }
      let(:work) { build(:work, edit_users: [user], edit_groups: [group]) }

      its(:edit_users) { is_expected.to contain_exactly(user.uid) }
      its(:edit_groups) { is_expected.to contain_exactly(group.name) }
    end
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
      let(:params) { { 'edit_users' => [user.access_id] } }
      let(:user) { create(:user) }

      before { allow(UserRegistrationService).to receive(:call).with(uid: user.access_id).and_return(user) }

      it 'adds the user as an editor' do
        expect(work.edit_users).to be_empty
        form.save
        work.reload
        expect(work.edit_users).to contain_exactly(user)
      end
    end

    context 'when the user does NOT exist' do
      let(:params) { { 'edit_users' => [access_id] } }
      let(:access_id) { 'we-aint-penn-state' }

      before { allow(UserRegistrationService).to receive(:call).with(uid: access_id).and_return(nil) }

      it 'does not add the user and reports an error' do
        expect(work.edit_users).to be_empty
        form.save
        expect(work.edit_users).to be_empty
        expect(form.errors.full_messages).to contain_exactly("Edit users #{access_id} does not exist")
      end
    end

    context 'when adding a group' do
      let(:params) { { 'edit_groups' => [group.name] } }
      let(:group) { create(:group) }

      it 'adds the group as an editor' do
        expect(work.edit_groups).to be_empty
        form.save
        work.reload
        expect(work.edit_groups).to contain_exactly(group)
      end
    end

    context 'when the group does NOT exist' do
      let(:params) { { 'edit_groups' => ['missing-group'] } }

      it 'adds the group as an editor' do
        expect(work.edit_groups).to be_empty
        form.save
        work.reload
        expect(work.edit_groups).to be_empty
      end
    end
  end
end
