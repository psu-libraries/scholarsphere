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

  describe '#decorated_work' do
    let(:work) { instance_double 'Work' }
    let(:work_version) { instance_double 'WorkVersion', work: work }

    it 'returns a decorated work' do
      allow(WorkDecorator).to receive(:new).with(work).and_return(:decorated_work)

      expect(decorator.decorated_work).to eq :decorated_work
    end
  end
end
