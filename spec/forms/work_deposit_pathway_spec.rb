# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkDepositPathway do
  subject(:pathway) { described_class.new(wv) }

  let(:wv) {
    instance_double(
      WorkVersion,
      work_type: type,
      attributes: {},
      id: 123,
      draft_curation_requested: draft_curation_requested
    )
  }
  let(:type) { nil }
  let(:draft_curation_requested) { false }

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
        it 'returns a WorkDepositPathway::DataAndCode::DetailsForm initialized with the work type' do
          form = pathway.details_form
          expect(form).to be_a WorkDepositPathway::DataAndCode::DetailsForm
          expect(form.id).to eq 123
        end
      end
    end
  end

  describe '#publish_form when the given work version has a scholarly works type' do
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
          form = pathway.publish_form
          expect(form).to be_a WorkDepositPathway::ScholarlyWorks::PublishForm
          expect(form.id).to eq 123
        end
      end
    end
  end

  describe '#publish_form when the given work version has a general type' do
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
        it 'returns the given WorkVersion' do
          form = pathway.publish_form
          expect(form).to eq wv
        end
      end
    end
  end

  describe '#publish_form when the given work version has a data and code type' do
    %w[
      dataset
      software_or_program_code
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns the given WorkVersion' do
          form = pathway.publish_form
          expect(form).to eq wv
        end
      end
    end
  end

  describe '#allows_visibility_change? when the given work version does not have a data and code type' do
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
        it 'returns true' do
          expect(pathway.allows_visibility_change?).to eq true
        end
      end
    end
  end

  describe '#allows_visibility_change? when the given work version has a data and code type' do
    %w[
      dataset
      software_or_program_code
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns false' do
          expect(pathway.allows_visibility_change?).to eq false
        end
      end
    end
  end

  describe '#allows_curation_request? when the given work version does not have a data and code type' do
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
        context 'when curation has been requested for the given work version' do
          let(:draft_curation_requested) { true }

          it 'returns false' do
            expect(pathway.allows_curation_request?).to eq false
          end
        end

        context 'when curation has not been requested for the given work version' do
          it 'returns false' do
            expect(pathway.allows_curation_request?).to eq false
          end
        end
      end
    end
  end

  describe '#allows_curation_request? when the given work version has a data and code type' do
    %w[
      dataset
      software_or_program_code
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        context 'when curation has been requested for the given work version' do
          let(:draft_curation_requested) { true }

          it 'returns false' do
            expect(pathway.allows_curation_request?).to eq false
          end
        end

        context 'when curation has not been requested for the given work version' do
          it 'returns true' do
            expect(pathway.allows_curation_request?).to eq true
          end
        end
      end
    end
  end

  describe '#work? when the given work version has a work type' do
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
      dataset
      software_or_program_code
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns true' do
          expect(pathway.work?).to eq true
        end
      end
    end
  end

  describe '#work? when the given work version does not have a work type' do
    let(:type) { 'collection' }

    it 'returns false' do
      expect(pathway.work?).to eq false
    end
  end

  describe '#data_and_code? when the given work version does not have a data and code type' do
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
        it 'returns false' do
          expect(pathway.data_and_code?).to eq false
        end
      end
    end
  end

  describe '#data_and_code? when the given work version has a data and code type' do
    %w[
      dataset
      software_or_program_code
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns true' do
          expect(pathway.data_and_code?).to eq true
        end
      end
    end
  end
end
