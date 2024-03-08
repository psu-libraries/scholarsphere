# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'
require_relative '../_shared_examples_for_details_form'

RSpec.describe WorkDepositPathway::DataAndCode::DetailsForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    build(
      :work_version,
      attributes: {
        'description' => description,
        'published_date' => '2024',
        'subtitle' => 'test subtitle',
        'keyword' => 'test keyword',
        'publisher' => 'test publisher',
        'identifier' => 'test identifier',
        'related_url' => 'test related_url',
        'subject' => 'test subject',
        'language' => 'test language',
        'based_near' => 'test location',
        'source' => 'test source',
        'version_name' => '1.0.0'
      }
    )
  }

  let(:description) { 'test description' }

  it_behaves_like 'a work deposit pathway form'
  it_behaves_like 'a work deposit pathway details form'

  describe '.form_fields' do
    it "returns a frozen array of the names of the form's fields" do
      expect(described_class.form_fields).to match_array %w{
        description
        published_date
        subtitle
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

  describe '#form_partial' do
    it 'returns scholarly_works_work_version' do
      expect(form.form_partial).to eq 'data_and_code_work_version'
    end
  end

  describe 'attribute initialization' do
    it "sets the form attributes correctly from the given object's attributes" do
      expect(form).to have_attributes(
        {
          description: 'test description',
          published_date: '2024',
          subtitle: 'test subtitle',
          keyword: ['test keyword'],
          publisher: ['test publisher'],
          identifier: ['test identifier'],
          related_url: ['test related_url'],
          subject: ['test subject'],
          language: ['test language'],
          based_near: ['test location'],
          source: ['test source'],
          version_name: '1.0.0'
        }
      )
    end
  end
end
