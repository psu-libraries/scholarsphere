# frozen_string_literal: true

require 'rails_helper'
require 'data_cite'

RSpec.describe 'minting a doi', skip: !ci_build? do
  let!(:work) { create(:work, versions: [work_version]) }
  let(:work_version) { build(:work_version, :able_to_be_published, work: nil) }

  let(:client) { DataCite::Client.new }

  it 'mints a doi correctly' do
    skip 'this can fail for unexpected reasons and should not prevent merges or test deploys'
    # Create a draft doi for the draft WorkVersion
    expect {
      DoiService.call(work_version)
    }.to change {
      work_version.reload.doi
    }.from(nil).to(a_string_matching(%r{#{client.prefix}/.+}))

    api_sleep
    _doi, draft_version_datacite_metadata = client.get(doi: work_version.doi)
    expect(draft_version_datacite_metadata.dig('data', 'attributes', 'published')).to be_blank

    # Publish the WorkVersion, and update the doi
    work_version.publish
    work_version.save!
    api_sleep
    DoiService.call(work_version)

    api_sleep
    _doi, published_verison_datacite_metadata = client.get(doi: work_version.doi)
    expect(published_verison_datacite_metadata.dig('data', 'attributes', 'published')).to be_present
    expect(published_verison_datacite_metadata.dig('data', 'attributes', 'url')).to eq(
      Rails.application.routes.url_helpers.resource_url(work_version.uuid)
    )

    # mint a DOI for the work
    work.reload
    expect {
      api_sleep
      DoiService.call(work)
    }.to change {
      work.reload.doi
    }.from(nil).to(a_string_matching(%r{#{client.prefix}/.+}))

    api_sleep
    _doi, work_datacite_metadata = client.get(doi: work.doi)
    expect(work_datacite_metadata.dig('data', 'attributes', 'published')).to be_present

    # Create a new version of the Work
    new_version = BuildNewWorkVersion.call(work_version)
    new_version.title = 'Updated Title'
    new_version.save!
    new_version.publish
    new_version.save!
    work.reload
    api_sleep
    DoiService.call(work)

    api_sleep
    _doi, updated_work_datacite_metadata = client.get(doi: work.doi)
    expect(updated_work_datacite_metadata.dig('data', 'attributes', 'titles', 0, 'title')).to eq 'Updated Title'
  end

  def api_sleep
    sleep 0.5
  end
end
