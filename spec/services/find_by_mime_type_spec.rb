# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FindByMimeType do
  subject { described_class.call(mime_types: types) }

  context 'when querying by all text types' do
    subject { described_class.call(mime_types: :text) }

    it { is_expected.to be_empty }
  end

  context 'when querying for a specific type' do
    let(:types) { 'image/png' }

    before { create(:work_version, :published, :with_files) }

    it 'yields the search result' do
      described_class.call(mime_types: 'image/png') do |resource|
        expect(resource).to be_a(FileResource)
      end
    end
  end
end
