# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'
require_relative '../_shared_examples_for_details_form'

RSpec.describe WorkDepositPathway::ScholarlyWorks::DetailsForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    build(
      :work_version,
      attributes: {
        'title' => 'test title',
        'description' => description,
        'published_date' => '2024',
        'subtitle' => 'test subtitle',
        'publisher_statement' => 'test publisher_statement',
        'keyword' => 'test keyword',
        'publisher' => 'test publisher',
        'identifier' => 'test identifier',
        'related_url' => 'test related_url',
        'subject' => 'test subject',
        'language' => 'test language'
      }
    )
  }

  let(:description) { 'test description' }

  it_behaves_like 'a work deposit pathway form'
  it_behaves_like 'a work deposit pathway details form'

  describe '.form_fields' do
    it "returns a frozen array of the names of the form's fields" do
      expect(described_class.form_fields).to match_array %w{
        title
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
      }

      expect(described_class.form_fields).to be_frozen
    end
  end

  describe '#form_partial' do
    it 'returns scholarly_works_work_version' do
      expect(form.form_partial).to eq 'scholarly_works_work_version'
    end
  end

  describe 'attribute initialization' do
    it "sets the form attributes correctly from the given object's attributes" do
      expect(form).to have_attributes(
        {
          title: 'test title',
          description: 'test description',
          published_date: '2024',
          subtitle: 'test subtitle',
          publisher_statement: 'test publisher_statement',
          keyword: ['test keyword'],
          publisher: ['test publisher'],
          identifier: ['test identifier'],
          related_url: ['test related_url'],
          subject: ['test subject'],
          language: ['test language']
        }
      )
    end
  end
end
