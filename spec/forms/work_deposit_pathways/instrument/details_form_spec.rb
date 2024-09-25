# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'
require_relative '../_shared_examples_for_details_form'

RSpec.describe WorkDepositPathway::Instrument::DetailsForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    build(
      :work_version,
      attributes: {
        'description' => description,
        'published_date' => '2021',
        'owner' => 'test owner',
        'manufacturer' => 'test manufacturer',
        'model' => 'test model',
        'instrument_type' => 'test type',
        'measured_variable' => 'test measured variable',
        'available_date' => '2022',
        'decommission_date' => '2024',
        'related_identifier' => 'test related id',
        'alternative_identifier' => 'test alternative id',
        'instrument_resource_type' => 'test resource type',
        'funding_reference' => 'test funding ref'
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
        owner
        identifier
        manufacturer
        model
        instrument_type
        measured_variable
        available_date
        decommission_date
        related_identifier
        alternative_identifier
        instrument_resource_type
        funding_reference
        description
        keyword
        language
        published_date
        publisher
        related_url
        subject
        subtitle
      }

      expect(described_class.form_fields).to be_frozen
    end
  end

  describe '#form_partial' do
    it 'returns instrument_work_version' do
      expect(form.form_partial).to eq 'instrument_work_version'
    end
  end

  describe 'attribute initialization' do
    it "sets the form attributes correctly from the given object's attributes" do
      expect(form).to have_attributes(
        {
          description: 'test description',
          published_date: '2021',
          owner: 'test owner',
          manufacturer: 'test manufacturer',
          model: 'test model',
          instrument_type: 'test type',
          measured_variable: 'test measured variable',
          available_date: '2022',
          decommission_date: '2024',
          related_identifier: 'test related id',
          alternative_identifier: 'test alternative id',
          instrument_resource_type: 'test resource type',
          funding_reference: 'test funding ref'
        }
      )
    end
  end
end
