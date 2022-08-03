# frozen_string_literal: true

RSpec.shared_examples 'a resource with a deposited at timestamp' do
  it { is_expected.to have_db_column(:deposited_at).of_type(:datetime) }
  it { is_expected.to validate_presence_of(:deposited_at) }

  describe '#deposited_at' do
    context 'with the default value' do
      subject(:resource) { described_class.new }

      it 'is set to the current time' do
        expect(resource.deposited_at.day).to eq(Time.zone.now.day)
      end
    end

    context 'with a specific value' do
      subject(:resource) { described_class.new(deposited_at: deposit_time) }

      let(:deposit_time) { 10.days.ago }

      its(:deposited_at) { is_expected.to eq(deposit_time) }
    end

    context 'with a string in a valid date format' do
      subject(:resource) { described_class.new(deposited_at: deposit_time.iso8601) }

      let(:deposit_time) { 8.days.ago }

      # @note Converting an iso8601 string to a Time object looses milisecond precision, so we just compare the days to
      # be sure.
      it 'converts to a Time object' do
        expect(resource.deposited_at.day).to eq(deposit_time.day)
      end
    end

    context 'with a string in an INVALID date format' do
      subject(:resource) { described_class.new(deposited_at: deposit_time) }

      let(:deposit_time) { 'no time' }

      it 'is set to the current time' do
        expect(resource.deposited_at.day).to eq(Time.zone.now.day)
      end
    end
  end
end
