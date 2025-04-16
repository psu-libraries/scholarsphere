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
      accessibility_remediation_requested: accessibility_remediation_requested,
      doi_blank?: doi_blank,
      work: work,
      file_version_memberships: [file_version_membership1, file_version_membership2]
    )
  }
  let(:type) { nil }
  let(:draft_curation_requested) { false }
  let(:accessibility_remediation_requested) { false }
  let(:doi_blank) { false }
  let(:file_version_membership1) { instance_double(FileVersionMembership, accessibility_failures?: true) }
  let(:file_version_membership2) { instance_double(FileVersionMembership, accessibility_failures?: false) }
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

    context 'when the given work version has an instrument type' do
      %w[
        instrument
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

    context 'when the given work version does not have a data and code, instrument, or grad culminating experience type' do
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

  describe '#allows_accessibility_remediation_request?' do
    context 'when in an allowable pathway' do
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
          context 'when remediation has been requested for the given work version' do
            let(:accessibility_remediation_requested) { true }

            it 'returns false' do
              expect(pathway.allows_accessibility_remediation_request?).to eq false
            end
          end

          context 'when remediation has not been requested for the given work version' do
            context 'when curation has been requested for the given work version' do
              let(:draft_curation_requested) { true }

              it 'returns false' do
                expect(pathway.allows_accessibility_remediation_request?).to eq false
              end
            end

            context 'when curation has not been requested for the given work version' do
              context 'when all files passed accessibility check' do
                let(:file_version_membership1) { instance_double(FileVersionMembership, accessibility_failures?: false) }

                it 'returns false' do
                  expect(pathway.allows_accessibility_remediation_request?).to eq false
                end
              end

              context 'when one of the files has failed an accessibility check' do
                it 'returns false' do
                  expect(pathway.allows_accessibility_remediation_request?).to eq true
                end
              end
            end
          end
        end
      end
    end

    context 'when in data and code pathway' do
      %w[
        dataset
        software_or_program_code
      ].each do |t|
        let(:type) { t }
        it 'returns false' do
          expect(pathway.allows_accessibility_remediation_request?).to eq false
        end
      end
    end

    context 'when in instrument pathway' do
      %w[
        instrument
      ].each do |t|
        let(:type) { t }
        it 'returns false' do
          expect(pathway.allows_accessibility_remediation_request?).to eq false
        end
      end
    end
  end

  describe '#allows_accessibility_remediation_request? when the given work version does not have a work type' do
    let(:type) { 'collection' }

    it 'returns false' do
      expect(pathway.allows_accessibility_remediation_request?).to eq false
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

  describe '#fields_to_reset' do
    let(:data_and_code) { 'dataset' }
    let(:grad_culminating_experience) { 'masters_culminating_experience' }
    let(:general) { 'audio' }
    let(:scholarly_work) { 'article' }

    context 'when the current work type is scholarly work' do
      let(:type) { scholarly_work }

      context 'when the original type was data and code' do
        it 'returns the fields in data and code that are not in scholarly work' do
          expect(pathway.fields_to_reset(data_and_code)).to match(
            ['based_near',
             'source',
             'version_name']
          )
        end
      end

      context 'when the original type was grad culminating experience' do
        it 'returns the fields in grad culminating experience that are not in scholarly work' do
          expect(pathway.fields_to_reset(grad_culminating_experience)).to match(
            ['sub_work_type',
             'program',
             'degree',
             'mint_doi_requested']
          )
        end
      end

      context 'when the original type was general' do
        it 'returns the fields in general that are not in scholarly work' do
          expect(pathway.fields_to_reset(general)).to match(
            ['based_near',
             'source',
             'version_name']
          )
        end
      end
    end

    context 'when the current work type is data and code' do
      let(:type) { data_and_code }

      context 'when original type was scholarly work' do
        it 'returns the fields in scholarly work that are not in data and code' do
          expect(pathway.fields_to_reset(scholarly_work)).to match(
            ['publisher_statement',
             'identifier']
          )
        end
      end

      context 'when original type was grad culminating experience' do
        it 'returns the fields in data and code that are not in grad culminating experience' do
          expect(pathway.fields_to_reset(grad_culminating_experience)).to match(
            ['sub_work_type',
             'program',
             'degree',
             'mint_doi_requested']
          )
        end
      end

      context 'when original type was general' do
        it 'returns the fields in general that are not in data and code' do
          expect(pathway.fields_to_reset(general)).to match(
            ['publisher_statement',
             'identifier']
          )
        end
      end
    end

    context 'when the current work type is grad culminating experience' do
      let(:type) { grad_culminating_experience }

      context 'when original type was scholarly work' do
        it 'returns the fields in scholarly work that are not in grad culminating experience' do
          expect(pathway.fields_to_reset(scholarly_work)).to match(
            ['publisher_statement',
             'identifier',
             'subject',
             'publisher',
             'subtitle']
          )
        end
      end

      context 'when original type was data and code' do
        it 'returns the fields in data and code that are not in grad culminating experience' do
          expect(pathway.fields_to_reset(data_and_code)).to match(
            ['based_near',
             'source',
             'version_name',
             'subject',
             'publisher',
             'subtitle']
          )
        end
      end

      context 'when original type was general' do
        it 'returns the fields in general that are not in grad culminating experience' do
          expect(pathway.fields_to_reset(general)).to match(
            ['publisher_statement',
             'identifier',
             'based_near',
             'source',
             'version_name',
             'subject',
             'publisher',
             'subtitle']
          )
        end
      end
    end

    context 'when the current type is general' do
      let(:type) { general }

      context 'when original type was scholarly work' do
        it 'returns the fields in scholarly work that are not in general' do
          expect(pathway.fields_to_reset(scholarly_work)).to eq([])
        end
      end

      context 'when original type was data and code' do
        it 'returns the fields in data and code that are not in general' do
          expect(pathway.fields_to_reset(data_and_code)).to eq([])
        end
      end

      context 'when original type was grad culminating experience' do
        it 'returns the fields in grad culminating experience that are not in general' do
          expect(pathway.fields_to_reset(grad_culminating_experience)).to match(
            ['sub_work_type',
             'program',
             'degree',
             'mint_doi_requested']
          )
        end
      end
    end
  end
end
