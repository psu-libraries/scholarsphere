# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'

RSpec.describe WorkDepositPathway::Instrument::ContributorsForm, type: :model do
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

  describe 'delegations' do
    it { is_expected.to delegate_method(:owner).to(:work_version) }
    it { is_expected.to delegate_method(:manufacturer).to(:work_version) }
    it { is_expected.to delegate_method(:contributor).to(:work_version) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:owner) }
    it { is_expected.to validate_presence_of(:manufacturer) }
  end

  describe '#form_partial' do
    it 'returns the correct partial name' do
      expect(form.form_partial).to eq('instrument_work_version')
    end
  end

  describe '#build_form' do
    let(:actor) { instance_double(Actor) }

    before do
      allow(wv).to receive(:build_creator)
    end

    it 'does not call any methods on the work_version' do
      form.build_form(actor)
      expect(wv).not_to have_received(:build_creator)
    end
  end
end
