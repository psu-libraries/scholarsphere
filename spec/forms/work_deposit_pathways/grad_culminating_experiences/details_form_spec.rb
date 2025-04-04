# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'
require_relative '../_shared_examples_for_details_form'

RSpec.describe WorkDepositPathway::GradCulminatingExperiences::DetailsForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    build(
      :work_version,
      attributes: {
        'title' => 'test title',
        'description' => description,
        'published_date' => '2024',
        'sub_work_type' => 'Capstone Project',
        'program' => 'Computer Science',
        'degree' => 'Master of Science',
        'keyword' => 'test keyword',
        'related_url' => 'test related_url',
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
        description
        published_date
        keyword
        related_url
        language
        sub_work_type
        program
        degree
      }

      expect(described_class.form_fields).to be_frozen
    end
  end

  describe '#form_partial' do
    it 'returns grad_culminating_experiences_work_version' do
      expect(form.form_partial).to eq 'grad_culminating_experiences_work_version'
    end
  end

  describe 'attribute initialization' do
    it "sets the form attributes correctly from the given object's attributes" do
      expect(form).to have_attributes(
        {
          description: 'test description',
          published_date: '2024',
          sub_work_type: 'Capstone Project',
          program: 'Computer Science',
          degree: 'Master of Science',
          keyword: ['test keyword'],
          related_url: ['test related_url'],
          language: ['test language']
        }
      )
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:sub_work_type) }
    it { is_expected.to validate_presence_of(:program) }
    it { is_expected.to validate_presence_of(:degree) }
  end
end
