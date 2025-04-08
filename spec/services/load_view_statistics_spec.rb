# frozen_string_literal: true

require 'rails_helper'

describe LoadViewStatistics, type: :model do
  # Helper method to quickly make Dates
  def d(str)
    Date.parse(str)
  end

  describe '#call' do
    subject(:view_stats) { described_class.call(model: model) }

    let(:model) { create(:work_version, :draft) }
    let(:another_model) { create(:work_version, :draft) }

    before do
      {
        # Date           Count
        d('2020-06-01') => 1,
        d('2020-06-03') => 3,
        d('2020-06-02') => 2
      }.each do |date, count|
        model.view_statistics.create!(date: date, count: count)
      end

      another_model.view_statistics.create!(date: d('2020-06-01'), count: 100)
    end

    it 'returns an ordered 2d array of view statistics for the given model' do
      expect(view_stats).to eq(
        [
          [d('2020-06-01'), 1, 1],
          [d('2020-06-02'), 2, 3],
          [d('2020-06-03'), 3, 6]
        ]
      )
    end
  end
end
