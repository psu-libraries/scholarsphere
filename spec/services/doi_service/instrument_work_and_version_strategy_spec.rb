# frozen_string_literal: true

require 'rails_helper'
require 'data_cite'

RSpec.describe DoiService::InstrumentWorkAndVersionStrategy do
  describe '.applicable_to?' do
    context 'when the given object is a Work' do
      let(:obj) { Work.new(work_type: type) }

      context "when the given object has a work_type of 'instrument'" do
        let(:type) { 'instrument' }

        it 'returns true' do
          expect(described_class.applicable_to?(obj)).to eq true
        end
      end

      context "when the given object does not have a work_type of 'instrument'" do
        let(:type) { 'other' }

        it 'returns false' do
          expect(described_class.applicable_to?(obj)).to eq false
        end
      end
    end

    context 'when the given object is a WorkVersion' do
      let(:work) { Work.new(work_type: type) }
      let(:obj) { WorkVersion.new(work: work) }

      context "when the given object has a work_type of 'instrument'" do
        let(:type) { 'instrument' }

        it 'returns true' do
          expect(described_class.applicable_to?(obj)).to eq true
        end
      end

      context "when the given object does not have a work_type of 'instrument'" do
        let(:type) { 'other' }

        it 'returns false' do
          expect(described_class.applicable_to?(obj)).to eq false
        end
      end
    end

    context 'when the given object is not a Work or a WorkVersion' do
      let(:obj) { instance_double Collection, work_type: type }

      context "when the given object has a work_type of 'instrument'" do
        let(:type) { 'instrument' }

        it 'returns false' do
          expect(described_class.applicable_to?(obj)).to eq false
        end
      end

      context "when the given object does not have a work_type of 'instrument'" do
        let(:type) { 'other' }

        it 'returns false' do
          expect(described_class.applicable_to?(obj)).to eq false
        end
      end
    end
  end
end
