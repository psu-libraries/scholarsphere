# frozen_string_literal: true

require 'rails_helper'
require_relative '_shared_examples_for_work_deposit_pathway_form'

RSpec.describe WorkDepositPathway::ContributorsFormBase, type: :model do
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
        'instrument_resource_type' => 'test resource type',
        'funding_reference' => 'test funding ref'
      }
    )
  }

  let(:description) { 'test description' }

  it_behaves_like 'a work deposit pathway form'

  describe 'delegations' do
    it { is_expected.to delegate_method(:creators).to(:work_version) }
    it { is_expected.to delegate_method(:build_creator).to(:work_version) }
    it { is_expected.to delegate_method(:contributor).to(:work_version) }
  end

  describe '#creators_attributes=' do
    let(:attributes) { { display_name: 'Creator 1', email: 'abc123@email.com' } }

    before do
      allow(wv).to receive(:creators_attributes=)
    end

    it 'assigns the creators attributes to the work version' do
      form.creators_attributes = attributes
      expect(wv).to have_received(:creators_attributes=).with(attributes)
    end
  end

  describe '#contributor=' do
    let(:contributor) { ['Test User'] }

    before do
      allow(wv).to receive(:contributor=)
    end

    it 'assigns the contributors to the work version' do
      form.contributor = contributor
      expect(wv).to have_received(:contributor=).with(contributor)
    end
  end

  describe '#form_partial' do
    it 'returns the correct partial name' do
      expect(form.form_partial).to eq('non_instrument_work_version')
    end
  end

  describe 'validations' do
    context 'when no surname' do
      before { wv.creators << build(:authorship, { display_name: 'Creator 1', given_name: 'John', surname: nil, email: 'abc123@email.com' }) }

      it 'returns an error and asks for a surname' do
        expect(form).not_to be_valid
        expect(form.errors[:creators]).to include('Each creator must have a given name and a surname.')
      end
    end

    context 'when no given name' do
      before { wv.creators << build(:authorship, { display_name: 'Creator 1', given_name: nil, surname: 'Doe', email: 'abc123@email.com' }) }

      it 'returns an error and asks for a given name' do
        expect(form).not_to be_valid
        expect(form.errors[:creators]).to include('Each creator must have a given name and a surname.')
      end
    end

    context 'when valid' do
      before { wv.creators << build(:authorship, { display_name: 'Creator 1', given_name: 'John', surname: 'Doe', email: 'abc123@email.com' }) }

      it 'returns valid' do
        expect(form).to be_valid
      end
    end
  end
end
