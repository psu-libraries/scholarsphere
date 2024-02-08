# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkDepositPathway do
  subject(:pathway) { described_class.new(wv) }

  let(:wv) {
    instance_double(
      WorkVersion,
      work_type: type,
      attributes: {},
      id: 123
    )
  }
  let(:type) { nil }

  describe '#details_form when the given work version has a scholarly works type' do
    %w[
      article
      book
      capstone_project
      conference_proceeding
      dissertation
      masters_culminating_experience
      masters_thesis
      part_of_book
      report
      research_paper
      thesis
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns a WorkDepositPathway::ScholarlyWorks::DetailsForm initialized with the work type' do
          form = pathway.details_form
          expect(form).to be_a WorkDepositPathway::ScholarlyWorks::DetailsForm
          expect(form.id).to eq 123
        end
      end
    end
  end

  describe '#details_form when the given work version has a general type' do
    %w[
      audio
      image
      journal
      map_or_cartographic_material
      other
      poster
      presentation
      project
      unspecified
      video
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns a WorkDepositPathway::General::DetailsForm initialized with the work type' do
          form = pathway.details_form
          expect(form).to be_a WorkDepositPathway::General::DetailsForm
          expect(form.id).to eq 123
        end
      end
    end
  end

  describe '#details_form when the given work version has a data and code type' do
    %w[
      dataset
      software_or_program_code
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns the given WorkVersion' do
          form = pathway.details_form
          expect(form).to eq wv
        end
      end
    end
  end
end
