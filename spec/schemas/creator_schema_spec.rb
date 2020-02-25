# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatorSchema do
  subject(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'when the resource has creators' do
      let(:resource) { create(:work_version, :with_creators) }

      its(:document) do
        is_expected.to eq(
          creators_sim: resource.creators.map(&:default_alias),
          creator_aliases_tesim: resource.creator_aliases.map(&:alias)
        )
      end
    end

    context 'when the resource does not have creators' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      its(:document) { is_expected.to be_empty }
    end
  end
end
