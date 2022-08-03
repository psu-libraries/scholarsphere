# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorStatsPresenter do
  let(:work_version) { create(:work_version, :with_files) }
  let(:another_work) { create(:work_version, :with_files) }
  let(:actor) { work_version.depositor }

  before do
    ViewStatistic.create(
      date: 5.days.ago.to_date,
      count: 1,
      resource_type: 'FileResource',
      resource_id: work_version.file_resources.first.id
    )

    ViewStatistic.create(
      date: 10.days.ago.to_date,
      count: 2,
      resource_type: 'FileResource',
      resource_id: work_version.file_resources.first.id
    )

    ViewStatistic.create(
      date: 20.days.ago.to_date,
      count: 3,
      resource_type: 'FileResource',
      resource_id: work_version.file_resources.first.id
    )

    ViewStatistic.create(
      date: 30.days.ago.to_date,
      count: 4,
      resource_type: 'FileResource',
      resource_id: work_version.file_resources.first.id
    )

    ViewStatistic.create(
      date: 5.days.ago.to_date,
      count: 1,
      resource_type: 'FileResource',
      resource_id: another_work.file_resources.first.id
    )
  end

  describe '#file_downloads' do
    context 'when specifying a start date' do
      subject { described_class.new(actor: actor, beginning_at: 20.days.ago.to_date) }

      its(:file_downloads) { is_expected.to eq(6) }
    end

    context 'when specifying an end date' do
      subject { described_class.new(actor: actor, ending_at: 10.days.ago.to_date) }

      its(:file_downloads) { is_expected.to eq(9) }
    end

    context 'with no date restrictions' do
      subject { described_class.new(actor: actor) }

      its(:file_downloads) { is_expected.to eq(10) }
    end
  end

  describe '#total_files' do
    subject { described_class.new(actor: actor) }

    its(:total_files) { is_expected.to eq(1) }
  end
end
