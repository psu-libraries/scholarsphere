# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionSchema, type: :schema do
  let(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    let(:errors) { schema.document[:migration_errors_sim] }

    context 'when a work has migration errors' do
      let(:resource) { create(:work).versions.first }

      before do
        resource.creators = []
        resource.file_resources = []
      end

      it { expect(errors).not_to include(
        "Work versions file resources can't be blank",
        "Work versions creator aliases can't be blank"
      )}

      it { expect(errors).to include(
        "Files can't be blank",
        "Creators can't be blank"
      )}
    end

    context 'when the work is successfully published' do
      let(:resource) { create(:work, has_draft: false).versions.first }

      it { expect(errors).to be_empty }
    end
  end
end
