# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiSchema do
  subject(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'when the resource has #all_dois' do
      let(:resource) { build(:work_version, doi: FactoryBotHelpers.valid_doi) }

      its(:document) do
        is_expected.to eq(
          all_dois_ssim: [resource.doi]
        )
      end
    end

    context 'when the resource does not have creators' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      its(:document) { is_expected.to be_empty }
    end
  end
end
