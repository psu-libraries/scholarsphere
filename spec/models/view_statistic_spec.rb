# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ViewStatistic do
  describe 'table' do
    it { is_expected.to have_db_column(:count).of_type(:integer) }
    it { is_expected.to have_db_column(:date).of_type(:date) }
    it { is_expected.to have_db_column(:resource_type).of_type(:string) }
    it { is_expected.to have_db_column(:resource_id).of_type(:integer) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:legacy_identifier) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:resource) }
  end

  describe '#count' do
    context 'with a default record' do
      its(:count) { is_expected.to eq(0) }
    end
  end

  describe '#date' do
    subject(:view_statistic) { create(:view_statistic) }

    before { view_statistic.reload }

    its(:date) { is_expected.to eq(Time.zone.now.to_date) }
  end
end
