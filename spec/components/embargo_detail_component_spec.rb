# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoDetailComponent, type: :component do
  let(:content) { render_inline(described_class, work_version: work_version).to_s }
  let(:embargo_date) { DateTime.now + 6.days }
  let(:work) { build(:work, embargoed_until: embargo_date) }
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
    let(:work_version) { build(:work_version, :published, work: work) }

    it 'displays a message' do
      expect(content).to include("Embargoed until #{embargo_date.strftime('%Y-%m-%d')}")
      expect(content).to include('Files are not available during the embargo.')
    end
  end

  context 'when the user has edit access to the work' do
    let(:work_version) { build(:work_version, :published, work: work) }
    let(:user) { work.depositor.user }

    it 'displays a message' do
      expect(content).to include("Embargoed until #{embargo_date.strftime('%Y-%m-%d')}")
      expect(content).to include('You have permission to access the files during the embargo.')
    end
  end

  context 'when the user is viewing the work from their dashboard' do
    let(:work_version) { build(:work_version, :published, work: work) }
    let(:user) { work.depositor.user }
    let(:controller_name) { 'work_versions' }

    it 'displays a message' do
      expect(content).to include("Embargoed until #{embargo_date.strftime('%Y-%m-%d')}")
      expect(content).to include('You have permission to access the files during the embargo.')
      expect(content).to include('Public link')
    end
  end

  context 'when the work version is not embargoed' do
    let(:work_version) { build(:work_version, :published, work: work) }
    let(:work) { build(:work) }

    specify do
      expect { content }.to raise_error(ArgumentError, 'component must be used with an embargoed work')
    end
  end
end
