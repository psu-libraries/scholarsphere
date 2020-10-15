# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionDecorator do
  subject(:decorator) { described_class.new(work_version) }

  let(:work_version) { instance_spy('WorkVersion') }

  it 'extends ResourceDecorator' do
    expect(described_class).to be < ResourceDecorator
  end

  describe '#display_version_short' do
    subject { decorator.display_version_short }

    context 'when no version_name exists' do
      let(:work_version) { instance_spy('WorkVersion', version_name: nil, version_number: 3) }

      it { is_expected.to eq 'V3' }
    end

    context 'when there is a version_name' do
      let(:work_version) { instance_spy('WorkVersion', version_name: '1.2.3') }

      it { is_expected.to eq 'V1.2.3' }
    end
  end

  describe '#display_version_long' do
    subject { decorator.display_version_long }

    context 'when no version_name exists' do
      let(:work_version) { instance_spy('WorkVersion', version_name: nil, version_number: 3) }

      it { is_expected.to eq 'Version 3' }
    end

    context 'when there is a version_name' do
      let(:work_version) { instance_spy('WorkVersion', version_name: '1.2.3') }

      it { is_expected.to eq 'Version 1.2.3' }
    end
  end

  describe '#display_date' do
    let(:date) { Time.zone.parse('2019-11-04 12:03:00') }
    let(:work_version) { instance_spy('WorkVersion', updated_at: date, published_date: '2020~') }

    context 'with a draft version' do
      before { allow(work_version).to receive(:draft?).and_return true }

      its(:display_date) { is_expected.to eq 'Updated November 04, 2019' }
    end

    context 'with a published version' do
      before { allow(work_version).to receive(:draft?).and_return false }

      its(:display_date) { is_expected.to eq 'Published circa 2020' }
    end
  end

  describe '#decorated_work' do
    let(:work) { instance_double 'Work' }
    let(:work_version) { instance_double 'WorkVersion', work: work }

    it 'returns a decorated work' do
      allow(WorkDecorator).to receive(:new).with(work).and_return(:decorated_work)

      expect(decorator.decorated_work).to eq :decorated_work
    end
  end

  describe '#resource_with_doi' do
    let(:work) { instance_double 'Work' }
    let(:work_version) { instance_double 'WorkVersion', work: work }

    it 'returns the parent work' do
      expect(decorator.resource_with_doi).to eq work
    end
  end
end
