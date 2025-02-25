# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument do
  subject (:solr_document) { described_class.new(document) }

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

  describe '#to_semantic_values' do
    let(:document) { { id: '123', identifier_tesim: ['user doi 1', 'user doi 2'] } }
    let(:identifier) { solr_document.to_semantic_values[:identifier] }

    context 'when the resource has a minted DOI' do
      let(:document) { { id: '123', identifier_tesim: ['user doi 1', 'user doi 2'], all_dois_ssim: ['10.123.456'] } }

      it 'has the correct identifiers' do
        expect(identifier.count).to eq 4
        expect(identifier).to eq [
          "#{Rails.application.routes.url_helpers.root_url}resources/123",
          'user doi 1',
          'user doi 2',
          '10.123.456'
        ]
      end
    end

    context 'when the resource does not have a minted DOI' do
      it 'has the correct identifiers' do
        expect(identifier.count).to eq 3
        expect(identifier).to eq [
          "#{Rails.application.routes.url_helpers.root_url}resources/123",
          'user doi 1',
          'user doi 2'
        ]
      end
    end

    context 'when the resource has no DOIs' do
      let(:document) { { id: '123' } }

      it 'has the correct identifiers' do
        expect(identifier.count).to eq 1
        expect(identifier).to eq [
          "#{Rails.application.routes.url_helpers.root_url}resources/123"
        ]
      end
    end
  end
end
