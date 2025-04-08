# frozen_string_literal: true

require 'rails_helper'

describe 'migration' do
  describe ':statistics' do
    let(:csv) { Pathname.new(fixture_paths.first).join('s3_export_stats.csv') }

    before { allow(ImportStatisticsJob).to receive(:perform_later) }

    it 'calls the ImportStatisticsJob' do
      Rake::Task['migration:statistics'].invoke(csv)
      expect(ImportStatisticsJob).to have_received(:perform_later).exactly(8).times
    end
  end
end
