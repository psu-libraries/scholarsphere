# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawnDetailComponent, type: :component do
  let(:content) { render_inline(described_class.new(work_version: work_version)).to_s }
  let(:work) { build(:work) }
  let(:user) { build(:user) }
  let(:controller_name) { 'application' }
  let(:mock_controller) do
    instance_double('ApplicationController', current_user: user, controller_name: controller_name)
  end

  # @todo Is there a better way to do this? We could use the same methods we use to test controllers
  # and use Devise helpers, but that requires more heavy re-wiring. We can revisit later and look over the gem's
  # documentation more and, if needed, submit some issues.
  before do
    allow_any_instance_of(described_class).to receive(:controller).and_return(mock_controller)
  end

  context 'when the user does not have edit access to the work' do
    let(:work_version) { build(:work_version, :withdrawn, work: work) }

    it 'displays a message' do
      expect(content).to include I18n.t('withdrawn.heading')
      expect(content).to include I18n.t('withdrawn.public_message')
    end
  end

  context 'when the user has edit access to the work' do
    let(:work_version) { build(:work_version, :withdrawn, work: work) }
    let(:user) { work.depositor.user }

    it 'displays a message' do
      expect(content).to include I18n.t('withdrawn.heading')
      expect(content).to include I18n.t('withdrawn.edit_message')
    end
  end

  context 'when the work version is not withdrawn' do
    let(:work_version) { build(:work_version, :published, work: work) }
    let(:work) { build(:work) }

    specify do
      expect(content).to be_empty
    end
  end
end
