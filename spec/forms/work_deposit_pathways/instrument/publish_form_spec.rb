# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'

RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = nil
RSpec.describe WorkDepositPathway::Instrument::PublishForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) {
    build(
      :work_version,
      work: build(:work, work_type: 'instrument'),
      title: 'test title',
      description: description,
      published_date: '2021',
      owner: 'test owner',
      manufacturer: 'test manufacturer',
      model: 'test model',
      instrument_type: 'test type',
      measured_variable: 'test measured variable',
      available_date: '2022',
      decommission_date: '2024',
      related_identifier: 'test related id',
      instrument_resource_type: 'test resource type',
      funding_reference: 'test funding ref'
    )
  }

  let(:description) { 'test description' }

  it_behaves_like 'a work deposit pathway form'

  it { is_expected.to delegate_method(:aasm_state).to(:work_version) }
  it { is_expected.to delegate_method(:publish).to(:work_version) }
  it { is_expected.to delegate_method(:file_resources).to(:work_version) }
  it { is_expected.to delegate_method(:creators).to(:work_version) }
  it { is_expected.to delegate_method(:contributor).to(:work_version) }
  it { is_expected.to delegate_method(:file_version_memberships).to(:work_version) }
  it { is_expected.to delegate_method(:initial_draft?).to(:work_version) }
  it { is_expected.to delegate_method(:aasm).to(:work_version) }
  it { is_expected.to delegate_method(:update_column).to(:work_version) }
  it { is_expected.to delegate_method(:set_thumbnail_selection).to(:work_version) }

  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:manufacturer) }

  describe '#aasm_state=' do
    before { allow(wv).to receive(:aasm_state=) }

    let(:arg) { double }

    it 'delegates to the given work version' do
      form.aasm_state = arg
      expect(wv).to have_received(:aasm_state=).with(arg)
    end
  end

  describe '#work_attributes=' do
    before { allow(wv).to receive(:work_attributes=) }

    let(:arg) { double }

    it 'delegates to the given work version' do
      form.work_attributes = arg
      expect(wv).to have_received(:work_attributes=).with(arg)
    end
  end

  describe '#creators_attributes=' do
    before { allow(wv).to receive(:creators_attributes=) }

    let(:arg) { double }

    it 'delegates to the given work version' do
      form.creators_attributes = arg
      expect(wv).to have_received(:creators_attributes=).with(arg)
    end
  end

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
        contributor
        depositor_agreement
        psu_community_agreement
        accessibility_agreement
        sensitive_info_agreement
        rights
      }

      expect(described_class.form_fields).to be_frozen
    end
  end

  describe 'attribute initialization' do
    it "sets the form attributes correctly from the given object's attributes" do
      expect(form).to have_attributes(
        {
          title: 'test title',
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
          instrument_resource_type: 'test resource type',
          funding_reference: 'test funding ref'
        }
      )
    end
  end

  describe 'validation' do
    context "when the form's work version is otherwise valid for publishing" do
      let(:wv) {
        build(:work_version,
              :with_creators,
              description: 'description',
              published_date: '2020',
              owner: 'owner',
              manufacturer: 'manufacturer')
      }

      context "when the form's work version is published" do
        before { wv.publish }

        context "when the form's work version has an image file that does not match 'readme'" do
          before { wv.file_resources << build(:file_resource) }

          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is invalid' do
              expect(form).not_to be_valid
              expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end
        end

        context "when the form's work version does not have an image file" do
          before { wv.file_resources << build(:file_resource, :pdf) }

          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is invalid' do
              expect(form).not_to be_valid
              expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              end
            end
          end
        end
      end

      context "when the form's work version is not published" do
        context "when the form's work version has an image file with a name that does not match 'readme'" do
          before { wv.file_resources << build(:file_resource) }

          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is valid' do
              expect(form).to be_valid
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end
        end

        context "when the form's work version does not have an image file" do
          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is valid' do
              expect(form).to be_valid
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end
        end
      end
    end

    context "when the form's work version is not otherwise valid for publishing" do
      let(:wv) {
        build(:work_version,
              :with_creators,
              description: nil,
              published_date: '2020',
              owner: 'owner',
              manufacturer: 'manufacturer')
      }

      context "when the form's work version is published" do
        before { wv.publish }

        context "when the form's work version has an image file with a name that does not match 'readme'" do
          before { wv.file_resources << build(:file_resource) }

          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is invalid' do
              expect(form).not_to be_valid
              expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end
          end
        end

        context "when the form's work version does not have an image file" do
          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is invalid' do
              expect(form).not_to be_valid
              expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
              expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is invalid' do
                expect(form).not_to be_valid
                expect(form.errors[:file_resources]).to include(I18n.t('activemodel.errors.models.work_version.attributes.file_resources.readme_and_image'))
                expect(form.errors[:description]).to include(I18n.t('activerecord.errors.models.work_version.attributes.description.blank'))
              end
            end
          end
        end
      end

      context "when the form's work version is not published" do
        context "when the form's work version has aan image file with a name that does not match 'readme'" do
          before { wv.file_resources << build(:file_resource) }

          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is valid' do
              expect(form).to be_valid
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end
        end

        context "when the form's work version does not have an image file" do
          context "when the form's work version does not have a file with a name that matches 'readme'" do
            it 'is valid' do
              expect(form).to be_valid
            end
          end

          context "when the form's work version has a file named 'README.md" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_md) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end

          context "when the form's work version has a file named 'readme.txt" do
            context 'when the file is empty' do
              before { wv.file_resources << build(:file_resource, :empty_readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end

            context 'when the file is not empty' do
              before { wv.file_resources << build(:file_resource, :readme_txt) }

              it 'is valid' do
                expect(form).to be_valid
              end
            end
          end
        end
      end
    end
  end

  describe '#form_partial' do
    it 'returns instrument_work_version' do
      expect(form.form_partial).to eq 'instrument_work_version'
    end
  end

  describe '#save' do
    let(:context) { double }

    before do
      allow(wv).to receive(:save).with(context: context).and_return true
      allow(wv).to receive(:save).with(hash_including(validate: false))
      allow(wv).to receive(:attributes=)
    end

    # RSpec mocks _cumulatively_ record the number of times they've been called,
    # we need a way to say "from this exact point, you should have been called
    # once." We accomplish this by tearing down the mock and setting it back up.
    def mock_wv_save
      RSpec::Mocks.space.proxy_for(wv)&.reset

      allow(wv).to receive(:save).and_call_original
    end

    context "when the form's work version is valid" do
      context 'when the form is valid' do
        it "saves the form's work version" do
          form.save(context: context)
          expect(wv).to have_received(:save).with(context: context)
        end

        context 'when the work version saves successfully' do
          it 'returns true' do
            expect(form.save(context: context)).to eq true
          end
        end
      end

      context 'when the form is not valid' do
        before { wv.publish }

        it 'returns false' do
          expect(form.save(context: context)).to eq false
        end

        it 'does not persist the form data' do
          mock_wv_save
          form.save(context: context)
          expect(wv).not_to have_received(:save)
        end

        it 'sets errors on the form' do
          form.save(context: context)
          expect(form.errors[:file_resources]).not_to be_empty
        end
      end
    end

    context "when the form's work version is invalid" do
      before do
        wv.errors.add(:description, 'bad data!')
        allow(wv).to receive(:valid?).and_return false
      end

      context 'when the form is valid' do
        it "transfers the work version's errors to the form" do
          form.save(context: context)
          expect(form.errors[:description]).to include 'bad data!'
        end

        it 'does not persist the form data' do
          form.save(context: context)
          expect(wv).not_to have_received(:save)
        end

        it 'returns false' do
          expect(form.save(context: context)).to eq false
        end
      end

      context 'when the form is not valid' do
        before { wv.publish }

        it 'sets errors on the form' do
          form.save(context: context)
          expect(form.errors[:description]).not_to be_empty
        end

        it "transfers the work version's errors to the form" do
          form.save(context: context)
          expect(form.errors[:description]).to include 'bad data!'
        end

        it 'does not persist the form data' do
          form.save(context: context)
          expect(wv).not_to have_received(:save)
        end

        it 'returns false' do
          expect(form.save(context: context)).to eq false
        end
      end
    end
  end
end
