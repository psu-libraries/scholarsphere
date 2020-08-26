# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceDecorator do
  subject { described_class.new(resource) }

  it 'extends SimpleDelegator' do
    expect(described_class).to be < SimpleDelegator
  end

  describe '::decorate' do
    subject { described_class.decorate(resource) }

    context 'when given a WorkVersion' do
      let(:resource) { WorkVersion.new }

      it { is_expected.to be_a WorkVersionDecorator }
    end

    context 'when given a Work' do
      let(:resource) { Work.new }

      it { is_expected.to be_a WorkDecorator }
    end

    context 'when given a Collection' do
      let(:resource) { Collection.new }

      it { is_expected.to be_a CollectionDecorator }
    end

    context 'when given some other model' do
      specify { expect { described_class.decorate(User.new) }.to raise_error(ArgumentError) }
    end
  end

  describe '#partial_name' do
    context 'with a work' do
      let(:resource) { build(:work) }

      its(:partial_name) { is_expected.to eq('work') }
    end

    context 'with a work version' do
      let(:resource) { build(:work_version) }

      its(:partial_name) { is_expected.to eq('work_version') }
    end

    context 'with a collection' do
      let(:resource) { build(:collection) }

      its(:partial_name) { is_expected.to eq('collection') }
    end
  end

  describe '#display_work_type' do
    context 'with a work' do
      let(:resource) { build(:work) }

      its(:display_work_type) { is_expected.to eq('Dataset') }
    end

    context 'with a work version' do
      let(:resource) { build(:work_version) }

      its(:display_work_type) { is_expected.to eq('Dataset') }
    end

    context 'with a collection' do
      let(:resource) { build(:collection) }

      its(:display_work_type) { is_expected.to eq('Collection') }
    end
  end

  describe '#display_published_date' do
    before do
      allow(EdtfDate).to receive(:humanize).with('resource_published_date')
        .and_return(:delegated_to_edtf_humanize)
    end

    context 'with a work' do
      let(:resource) { build(:work) }

      its(:display_published_date) { is_expected.to be_nil }
    end

    context 'with a work version' do
      let(:resource) { build(:work_version, published_date: 'resource_published_date') }

      its(:display_published_date) { is_expected.to eq(:delegated_to_edtf_humanize) }
    end

    context 'with a collection' do
      let(:resource) { build(:collection, published_date: 'resource_published_date') }

      before do
        allow(EdtfDate).to receive(:humanize).with(resource.published_date)
          .and_return(:delegated_to_edtf_humanize)
      end

      its(:display_published_date) { is_expected.to eq(:delegated_to_edtf_humanize) }
    end
  end
end
