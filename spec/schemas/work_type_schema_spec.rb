# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkTypeSchema do
  subject(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'with a work' do
      let(:resource) { build(:work) }

      its(:document) do
        is_expected.to eq(
          display_work_type_ssi: Work::Types.display(Work::Types.default),
          work_type_ss: Work::Types.default
        )
      end
    end

    context 'with a work version' do
      let(:resource) { build(:work_version) }

      its(:document) do
        is_expected.to eq(
          display_work_type_ssi: Work::Types.display(Work::Types.default),
          work_type_ss: Work::Types.default
        )
      end
    end
  end

  describe '#reject' do
    let(:resource) { build(:work) }

    its(:reject) { is_expected.to contain_exactly(:work_type_tesim, :resource_type_tesim) }
  end
end
