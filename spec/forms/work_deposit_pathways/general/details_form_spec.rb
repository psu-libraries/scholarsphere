# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_details_form'

RSpec.describe WorkDepositPathway::General::DetailsForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    instance_double(
      WorkVersion,
      attributes: {
        'description' => 'test description',
        'published_date' => '2024',
        'subtitle' => 'test subtitle',
        'publisher_statement' => 'test publisher_statement',
        'keyword' => 'test keyword',
        'publisher' => 'test publisher',
        'identifier' => 'test identifier',
        'related_url' => 'test related_url',
        'subject' => 'test subject',
        'language' => 'test language',
        'based_near' => 'test location',
        'source' => 'test source',
        'version_name' => '1.0.0'
      },
      'indexing_source=': nil,
      'update_doi=': nil,
      valid?: valid,
      errors: errors,
      imported_metadata_from_rmd: imported_metadata_from_rmd_value
    )
  }

  let(:valid) { true }
  let(:errors) { {} }
  let(:imported_metadata_from_rmd_value) { true }

  it_behaves_like 'a work deposit pathway details form'

  it { is_expected.to delegate_method(:form_partial).to(:work_version) }

  it { is_expected.to allow_value(nil).for(:version_name) }
  it { is_expected.to allow_value('').for(:version_name) }
  it { is_expected.to allow_value('1.0.1').for(:version_name) }
  it { is_expected.to allow_value('1.2.3-beta').for(:version_name) }

  describe '.form_fields' do
    it "returns a frozen array of the names of the form's fields" do
      expect(described_class.form_fields).to match_array %w{
        description
        published_date
        subtitle
        publisher_statement
        keyword
        publisher
        identifier
        related_url
        subject
        language
        based_near
        source
        version_name
      }

      expect(described_class.form_fields).to be_frozen
    end
  end

  describe 'attribute initialization' do
    it "sets the form attributes correctly from the given object's attributes" do
      expect(form).to have_attributes(
        {
          description: 'test description',
          published_date: '2024',
          subtitle: 'test subtitle',
          publisher_statement: 'test publisher_statement',
          keyword: 'test keyword',
          publisher: 'test publisher',
          identifier: 'test identifier',
          related_url: 'test related_url',
          subject: 'test subject',
          language: 'test language',
          based_near: 'test location',
          source: 'test source',
          version_name: '1.0.0'
        }
      )
    end
  end

  describe "#show_autocomplete_form?" do
    it 'returns false' do
      expect(form.show_autocomplete_form?).to eq false
    end
  end

  describe "#imported_metadata_from_rmd?" do
    context "when the resource's imported_metadata_from_rmd attribute is true" do
      it 'returns true' do
        expect(form.imported_metadata_from_rmd?).to eq true
      end
    end

    context "when the resource's imported_metadata_from_rmd attribute is false" do
      let(:imported_metadata_from_rmd_value) { false }

      it 'returns false' do
        expect(form.imported_metadata_from_rmd?).to eq false
      end
    end
  end
end
