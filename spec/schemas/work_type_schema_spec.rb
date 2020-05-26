# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkTypeSchema do
  subject(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'with a work' do
      let(:resource) { build(:work) }

      its(:document) { is_expected.to eq(work_type_ssim: Work::Types.display(Work::Types.default)) }
    end

    context 'with a work version' do
      let(:resource) { build(:work_version) }

      its(:document) { is_expected.to eq(work_type_ssim: Work::Types.display(Work::Types.default)) }
    end
  end

  describe '#reject' do
    let(:resource) { build(:work) }

    its(:reject) { is_expected.to contain_exactly(:work_type_tesim, :resource_type_tesim) }
  end
end
