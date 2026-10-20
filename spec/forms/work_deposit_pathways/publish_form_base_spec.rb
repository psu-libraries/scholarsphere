# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkDepositPathway::PublishFormBase, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    build(
      :work_version,
      attributes: {
        'description' => 'test description',
        'published_date' => '2024',
        'subtitle' => 'test subtitle',
        'publisher_statement' => 'test publisher_statement',
        'keyword' => 'test keyword',
        'publisher' => 'test publisher',
        'identifier' => 'test identifier',
        'related_url' => 'test related_url',
        'subject' => 'test subject',
        'language' => 'test language',
        'based_near' => 'test location',
        'source' => 'test source',
        'version_name' => '1.0.0'
      }
    )
  }

  it_behaves_like 'a work deposit pathway form'
  it { is_expected.to delegate_method(:mirror_remediated_version_to_files!).to(:work_version) }
  it { is_expected.to delegate_method(:created_by_researcher_metadata_database?).to(:work_version) }
end
