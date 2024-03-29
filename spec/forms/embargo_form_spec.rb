# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoForm, type: :model do
  subject(:form) { described_class.new(work: work, params: params) }

  let(:work) { instance_spy('Work') }
  let(:params) { {} }

  describe 'initialization' do
    context 'when given params' do
      let(:params) { { 'embargoed_until' => '2020-11-04' } }

      it 'initializes with params' do
        allow(work).to receive(:embargoed?).and_return false
        form = described_class.new(work: work, params: params)
        expect(form.embargoed_until).to eq Time.zone.parse('2020-11-04').beginning_of_day
      end
    end
  end

  describe '#remove?' do
    it 'casts the `remove` param to a boolean' do
      expect(described_class.new(work: work, params: { 'remove' => 't' }).remove?).to eq true
      expect(described_class.new(work: work, params: { 'remove' => '1' }).remove?).to eq true
      expect(described_class.new(work: work, params: { 'remove' => 'f' }).remove?).to eq false
      expect(described_class.new(work: work, params: { 'remove' => '0' }).remove?).to eq false
      expect(described_class.new(work: work, params: { 'remove' => '' }).remove?).to eq  false
      expect(described_class.new(work: work, params: { 'remove' => nil }).remove?).to eq false
    end
  end

  describe '#embargoed_until' do
    context 'when not set by params' do
      context 'when the work has an embargoed_until value' do
        before { allow(work).to receive(:embargoed_until).and_return Time.zone.parse('2020-11-03 00:00:00') }

        it "formats the work's embargoed_until as a datestamp" do
          expect(form.embargoed_until).to eq Time.zone.parse('2020-11-03').beginning_of_day
        end
      end

      context 'when the work has no value for embargoed_until' do
        before { allow(work).to receive(:embargoed_until).and_return nil }

        specify { expect(form.embargoed_until).to be_blank }
      end
    end

    context 'when set by params' do
      let(:params) { { 'embargoed_until' => '2020-11-03' } }

      specify { expect(form.embargoed_until).to eq Time.zone.parse('2020-11-03').beginning_of_day }
    end
  end

  describe '#save' do
    before do
      allow(work).to receive(:embargoed_until=)
      allow(work).to receive(:save)

      form.save
    end

    let(:params) { { 'embargoed_until' => '2020-11-04' } }

    it "sets the work's embargoed_until to midnight of the given date" do
      expect(work).to have_received(:embargoed_until=).with(
        Time.zone.local(2020, 11, 0o4, 0o0, 0o0, 0o0)
      )
      expect(work).to have_received(:save)
    end

    context 'when `remove` is set' do
      let(:params) { { 'embargoed_until' => '2020-11-04', 'remove' => 't' } }

      it 'clears the embargo on the work' do
        expect(work).to have_received(:embargoed_until=).with(nil)
        expect(work).to have_received(:save)
      end
    end
  end
end
