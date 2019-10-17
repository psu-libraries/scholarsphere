# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrConfigurator do
  describe '#zip_file' do
    # subject (described_class.new.raw_data)

    it 'returns a zip file that we can read' do 
      result = described_class.new.zip_file
      contents = result.read
      expect(contents).to be_a(String)
      expect(contents).not_to be_empty
    end
  end

  # describe '#gets_configsets' do
  #   it 'does not have a configset' do
  #     configsets = described_class.new.configset_exists?('foo')
  #     expect(configsets).to be(false)
  #   end
  # end

  # describe '#collection_exists' do
  #   it 'does not have a collection' do
  #     result = described_class.new.collection_exists?('foo')
  #     expect(result).to be(false)
  #   end
  # end

  # describe '#create_collection' do
  #   it 'creates a collection' do
  #     result = described_class.new.create_collection('new_thing')
  #     expect(result).to be(true)
  #   end
  # end
end
