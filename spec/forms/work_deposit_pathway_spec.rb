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
      draft_curation_requested: draft_curation_requested,
      doi_blank?: doi_blank,
      work: work
    )
  }
  let(:type) { nil }
  let(:draft_curation_requested) { false }
  let(:doi_blank) { false }
  let(:work) { instance_double(Work) }

  describe '#details_form when the given work version has a scholarly works type' do
    %w[
      article
      book
      conference_proceeding
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

  describe '#details_form when the given work version has a grad culminating experiences type' do
    %w[
      masters_culminating_experience
      professional_doctoral_culminating_experience
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns a WorkDepositPathway::GradCulminatingExperiences::DetailsForm initialized with the work type' do
          form = pathway.details_form
          expect(form).to be_a WorkDepositPathway::GradCulminatingExperiences::DetailsForm
          expect(form.id).to eq 123
        end
      end
    end
  end

  describe '#publish_form when the given work version has a scholarly works type' do
    %w[
      article
      book
      conference_proceeding
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
          expect(form).to be_a WorkDepositPathway::DataAndCode::PublishForm
          expect(form.id).to eq 123
        end
      end
    end
  end

  describe '#publish_form when the given work version has a grad culminating experiences type' do
    %w[
      masters_culminating_experience
      professional_doctoral_culminating_experience
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns a WorkDepositPathway::GradCulminatingExperiences::PublishForm initialized with the work type' do
          form = pathway.publish_form
          expect(form).to be_a WorkDepositPathway::GradCulminatingExperiences::PublishForm
          expect(form.id).to eq 123
        end
      end
    end
  end

  describe '#allows_visibility_change? when the given work version does not have a data and code type' do
    %w[
      article
      book
      conference_proceeding
      masters_culminating_experience
      professional_doctoral_culminating_experience
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
      conference_proceeding
      masters_culminating_experience
      professional_doctoral_culminating_experience
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

  describe '#allows_mint_doi_request?' do
    context 'when the given work version has a data and code type' do
      %w[
        dataset
        software_or_program_code
      ].each do |t|
        let(:type) { t }

        context 'when the associated work does not have a doi' do
          let(:doi_blank) { true }

          context 'when doi minting is not already in progress' do
            before do
              allow_any_instance_of(DoiMintingStatus).to receive(:blank?).and_return(true)
            end

            it 'returns true' do
              expect(pathway.allows_mint_doi_request?).to eq true
            end
          end

          context 'when doi minting is already in progress' do
            before do
              allow_any_instance_of(DoiMintingStatus).to receive(:blank?).and_return(false)
            end

            it 'returns false' do
              expect(pathway.allows_mint_doi_request?).to eq false
            end
          end
        end

        context 'when the associated work has a doi' do
          it 'returns false' do
            expect(pathway.allows_mint_doi_request?).to eq false
          end
        end
      end
    end

    context 'when the given work version has a grad culminating experiences type' do
      %w[
        masters_culminating_experience
        professional_doctoral_culminating_experience
      ].each do |t|
        let(:type) { t }

        context 'when the associated work does not have a doi' do
          let(:doi_blank) { true }

          context 'when doi minting is not already in progress' do
            before do
              allow_any_instance_of(DoiMintingStatus).to receive(:blank?).and_return(true)
            end

            it 'returns true' do
              expect(pathway.allows_mint_doi_request?).to eq true
            end
          end

          context 'when doi minting is already in progress' do
            before do
              allow_any_instance_of(DoiMintingStatus).to receive(:blank?).and_return(false)
            end

            it 'returns false' do
              expect(pathway.allows_mint_doi_request?).to eq false
            end
          end
        end

        context 'when the associated work has a doi' do
          it 'returns false' do
            expect(pathway.allows_mint_doi_request?).to eq false
          end
        end
      end
    end

    context 'when the given work version does not have a data and code or grad culminating experience type' do
      %w[
        article
        book
        conference_proceeding
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
        it 'returns false' do
          expect(pathway.allows_mint_doi_request?).to eq false
        end
      end
    end
  end

  describe '#work? when the given work version has a work type' do
    %w[
      article
      book
      conference_proceeding
      masters_culminating_experience
      professional_doctoral_culminating_experience
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
      conference_proceeding
      masters_culminating_experience
      professional_doctoral_culminating_experience
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

  describe '#grad_culminating_experiences? when the given work version does not have a grad culminating experiences type' do
    %w[
      article
      book
      conference_proceeding
      dataset
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
      software_or_program_code
      unspecified
      video
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns false' do
          expect(pathway.grad_culminating_experiences?).to eq false
        end
      end
    end
  end

  describe '#grad_culminating_experiences? when the given work version has a grad culminating experiences type' do
    %w[
      masters_culminating_experience
      professional_doctoral_culminating_experience
    ].each do |t|
      let(:type) { t }

      context "when the given work version has a work type of #{t}" do
        it 'returns true' do
          expect(pathway.grad_culminating_experiences?).to eq true
        end
      end
    end
  end
end
