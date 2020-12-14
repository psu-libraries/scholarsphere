# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceDecorator do
  subject(:decorator) { described_class.new(resource) }

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

  describe '#display_doi' do
    let(:resource) { build_stubbed :work }

    before do
      allow(MintingStatusDoiComponent).to receive(:new).and_return(:minting_status_doi_component)
    end

    context 'when the resource has a doi' do
      before { resource.doi = 'abc/123' }

      it 'returns a new doi component, initialized with #resource_with_doi' do
        expect(decorator.display_doi).to eq :minting_status_doi_component
        expect(MintingStatusDoiComponent).to have_received(:new).with(resource: resource)
      end
    end

    context 'when the resource does not have a doi' do
      before { resource.doi = nil }

      it 'returns nil' do
        expect(decorator.display_doi).to be_nil
      end
    end
  end

  describe '#visibility_badge' do
    context 'with a WorkVersion' do
      let(:resource) { build_stubbed :work_version }

      its(:visibility_badge) { is_expected.to be_a(VisibilityBadgeComponent) }
    end

    context 'with a Work' do
      let(:resource) { build_stubbed :work }

      its(:visibility_badge) { is_expected.to be_a(VisibilityBadgeComponent) }
    end
  end

  describe '#first_creators' do
    context 'when there are only creators' do
      let(:resource) { build_stubbed :work_version, :with_creators, creator_count: 3 }

      its(:first_creators) { is_expected.to eq(resource.creator_aliases) }
    end

    context 'when there are more than three creators' do
      let(:resource) { build_stubbed :work_version, :with_creators, creator_count: 4 }

      its(:first_creators) { is_expected.to eq(resource.creator_aliases.take(3) + ['&hellip;']) }
    end
  end

  describe '#published_date_or_deposited_year' do
    subject { decorator.published_date_or_deposited_year }

    context 'when a work version has a missing published date' do
      let(:resource) { build(:work_version, published_date: nil) }

      it { is_expected.to eq(resource.deposited_at.year) }
    end

    context 'when a work version has invalid EDTF' do
      let(:resource) { build(:work_version, published_date: 'Last Thursday') }

      it { is_expected.to eq(resource.deposited_at.year) }
    end

    context 'when a work verison has valid EDTF' do
      let(:resource) { build(:work_version, :able_to_be_published) }

      it { is_expected.to eq Date.edtf(resource.published_date).year }
    end

    context 'when a work version has valid EDTF but an uncertain year' do
      let(:resource) { build(:work_version, published_date: '2002?-12') }

      it { is_expected.to eq(2002) }
    end

    context 'when a collection has a published date' do
      let(:resource) { build(:collection, :with_complete_metadata) }

      it { is_expected.to eq Date.edtf(resource.published_date).year }
    end

    context 'when a collection does NOT have a published date' do
      let(:resource) { build(:collection) }

      it { is_expected.to eq(resource.deposited_at.year) }
    end
  end
end
