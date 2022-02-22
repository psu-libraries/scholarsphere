# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PopulateExternalApps, type: :model, versioning: true do
  subject(:call_service) { described_class.call }

  let(:external_app) { create :external_app }
  let(:some_user) { create :user }

  # Note that I am using instance vars (`@work`) instead of the preferred
  # `let(:work)` syntax here because I need exact control over when and where
  # these records are created
  before do
    # Create a WorkVersion with PaperTrail set to the external app, to simulate
    # how the ingest controller worked historially
    PaperTrail.request(whodunnit: external_app.to_gid) do
      @work = create :work, versions_count: 1, has_draft: false
      @first_version = @work.versions.first
    end

    # Now create some edits and a new version with PaperTrail set to a User to
    # simulate how the regular controllers behave
    PaperTrail.request(whodunnit: some_user.to_gid) do
      @second_version = BuildNewWorkVersion.call(@first_version)
      @second_version.save!

      @work_created_by_user = create :work, versions_count: 2, has_draft: true
    end

    # Create a work with a totally invalid `whodunnit` gid, to test error handling
    PaperTrail.request(whodunnit: 'invalid_gid') do
      @work_with_invalid_whodunnit = create :work, versions_count: 1
    end
  end

  it 'migrates any external app ids found in PaperTrail to WorkVersion#external_app' do
    call_service

    # Correctly migrates a record with an external app in papertail
    expect(@first_version.reload.external_app).to eq external_app

    # Does not affect others
    expect(@second_version.reload.external_app).to be_nil
    expect(@work_created_by_user.reload.versions.map(&:external_app)).to eq [nil, nil]
    expect(@work_with_invalid_whodunnit.reload.versions.map(&:external_app)).to eq [nil]
  end
end
