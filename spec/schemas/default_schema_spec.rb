# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DefaultSchema do
  subject { described_class.new(resource: resource) }

  describe '#document' do
    context 'with a WorkVersion' do
      let(:resource) { create(:work_version) }

      its(:document) do
        is_expected.to include(
          aasm_state_tesim: ['draft'],
          title_tesim: [resource.title],
          uuid_ssi: resource.uuid,
          version_number_isi: resource.version_number,
          updated_at_dtsi: resource.updated_at,
          doi_tesim: []
        )
      end
    end
  end
end
