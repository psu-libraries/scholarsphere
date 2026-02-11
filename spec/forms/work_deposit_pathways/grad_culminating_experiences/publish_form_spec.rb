# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'

RSpec.describe WorkDepositPathway::GradCulminatingExperiences::PublishForm, type: :model do
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
        'language' => 'test language',
        'rights' => 'https://creativecommons.org/licenses/by/4.0/',
        'contributor' => 'test contributor',
        'remediated_version' => false
      }
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
  it { is_expected.to delegate_method(:mirror_remediated_version_to_files!).to(:work_version) }

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

  describe '#mint_doi_requested=' do
    before { allow(wv).to receive(:mint_doi_requested=) }

    let(:arg) { double }

    it 'delegates to the given work version' do
      form.mint_doi_requested = arg
      expect(wv).to have_received(:mint_doi_requested=).with(arg)
    end
  end

  describe '.form_fields' do
    it "returns a frozen array of the names of the form's fields" do
      expect(described_class.form_fields).to match_array %w{
        title
        description
        published_date
        keyword
        related_url
        language
        sub_work_type
        program
        degree
        rights
        depositor_agreement
        contributor
        mint_doi_requested
        psu_community_agreement
        accessibility_agreement
        sensitive_info_agreement
        remediated_version
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
          sub_work_type: 'Capstone Project',
          program: 'Computer Science',
          degree: 'Master of Science',
          keyword: ['test keyword'],
          related_url: ['test related_url'],
          language: ['test language'],
          rights: 'https://creativecommons.org/licenses/by/4.0/',
          contributor: ['test contributor'],
          remediated_version: false
        }
      )
    end
  end

  describe '#form_partial' do
    it 'returns grad_culminating_experiences_work_version' do
      expect(form.form_partial).to eq 'grad_culminating_experiences_work_version'
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:sub_work_type) }
    it { is_expected.to validate_presence_of(:program) }
    it { is_expected.to validate_presence_of(:degree) }
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

          it 'mirrors the remediated_version flag to associated file resources' do
            allow(wv).to receive(:mirror_remediated_version_to_files!)

            form.save(context: context)

            expect(wv).to have_received(:mirror_remediated_version_to_files!)
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
