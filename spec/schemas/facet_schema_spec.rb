# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FacetSchema do
  subject(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'with a work version' do
      let(:resource) { build(:work_version, :with_complete_metadata) }

      its(:document) do
        is_expected.to eq(
          keyword_sim: resource.keyword,
          subject_sim: resource.subject
        )
      end
    end

    context 'with a collection' do
      let(:resource) { build(:collection, :with_complete_metadata) }

      its(:document) do
        is_expected.to eq(
          keyword_sim: resource.keyword,
          subject_sim: resource.subject
        )
      end
    end
  end
end
