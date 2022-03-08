# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument, type: :model do
  subject { described_class.new(document) }

  describe '#deposited_at' do
    context 'when the value exists' do
      let(:document) { { deposited_at_dtsi: '2020-11-10T02:05:05Z' } }

      its(:deposited_at) { is_expected.to be_a(Time) }
    end

    context 'when the value is nil' do
      let(:document) { {} }

      its(:deposited_at) { is_expected.to be_nil }
    end
  end

  describe '#default_thumbnail?' do
    context 'when :thumbnail_selection_tesim cannot be found in the document' do
      let(:document) { {} }

      its(:default_thumbnail?) { is_expected.to be true }
    end

    context 'when :thumbnail_selection_tesim can be found in the document' do
      context "when the value is #{ThumbnailSelections::DEFAULT_ICON}" do
        let(:document) { { thumbnail_selection_tesim: ThumbnailSelections::DEFAULT_ICON } }

        its(:default_thumbnail?) { is_expected.to be true }
      end

      context "when the value not #{ThumbnailSelections::DEFAULT_ICON}" do
        let(:document) { { thumbnail_selection_tesim: ThumbnailSelections::AUTO_GENERATED } }

        its(:default_thumbnail?) { is_expected.to be false }
      end
    end
  end
end
