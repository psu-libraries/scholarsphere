# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionChangePresenter do
  subject(:presenter) { described_class.new(
    paper_trail_version: paper_trail_version,
    user: user
  ) }

  let(:paper_trail_version) { instance_spy 'PaperTrail::Version', item_type: 'WorkVersion' }
  let(:user) { instance_spy 'User' }

  it { is_expected.to delegate_method(:created_at).to(:paper_trail_version) }
  it { is_expected.to delegate_method(:event).to(:paper_trail_version) }
  it { is_expected.to delegate_method(:id).to(:paper_trail_version) }

  describe '#initialize' do
    context 'when the given PaperTrail::Version does not apply to a WorkVersion' do
      before { allow(paper_trail_version).to receive(:item_type).and_return('SomeOtherClass') }

      it { expect { presenter }.to raise_error(ArgumentError) }
    end
  end

  describe '#to_partial_path' do
    it { expect(presenter.to_partial_path).to eq 'work_version_change' }
  end

  describe '#action' do
    subject(:action) { presenter.action }

    context 'with a generic CRUD event' do
      it 'returns a titleized, past-tense version of the event' do
        allow(paper_trail_version).to receive(:event).and_return('create')
        expect(action).to eq 'Created'
      end
    end

    context 'when the WorkVersion has been published (a special update to aasm_state)' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'aasm_state' => [
            WorkVersion::STATE_DRAFT,
            WorkVersion::STATE_PUBLISHED
          ]
        )
      end

      it { is_expected.to eq 'Published' }
    end
  end

  describe '#timestamp' do
    let(:created_at) { Time.zone.parse('2019-10-21 15:10:00') }

    before { allow(paper_trail_version).to receive(:created_at).and_return(created_at) }

    it "returns a human-friendly version of the papertrail's #created_at" do
      expect(presenter.timestamp).to eq 'October 21, 2019 15:10'
    end
  end

  describe '#changed_attributes' do
    context 'when the WorkVersion has been updated' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'metadata' => [
            { 'title' => 'old', 'version_name' => 'old' },
            { 'title' => 'new', 'version_name' => 'new' }
          ]
        )
      end

      it 'returns an array of humanized metadata attributes that have changed' do
        expect(presenter.changed_attributes).to contain_exactly('Title', 'Version Name')
      end
    end

    context 'when the WorkVersion has some other event' do
      before { allow(paper_trail_version).to receive(:event).and_return('create') }

      it 'returns an empty array' do
        expect(presenter.changed_attributes).to eq []
      end
    end
  end

  describe '#changed_attributes_truncated' do
    context 'when there are lots of changed attributes' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'metadata' => [
            { 'title' => 'old', 'subtitle' => 'old', 'description' => 'old', 'keywords' => 'old', 'rights' => 'old' },
            { 'title' => 'new', 'subtitle' => 'new', 'description' => 'new', 'keywords' => 'new', 'rights' => 'new' }
          ]
        )
      end

      it 'returns an abbreviated list of them' do
        expect(presenter.changed_attributes_truncated).to contain_exactly(
          'Title', 'Subtitle', 'Description', 'and 2 more'
        )
      end
    end
  end

  describe '#diff_presenter' do
    let(:mock_diff) { { 'title' => %w(old new) } }
    let(:mock_diff_presenter) { instance_spy 'DiffPresenter' }

    before do
      allow(WorkVersionChangeDiff).to receive(:call).and_return(mock_diff)
      allow(DiffPresenter).to receive(:new).and_return(mock_diff_presenter)
    end

    it 'returns a DiffPresenter representative of this change' do
      expect(presenter.diff_presenter).to eq mock_diff_presenter
      expect(WorkVersionChangeDiff).to have_received(:call).with(paper_trail_version)
      expect(DiffPresenter).to have_received(:new).with(mock_diff)
    end
  end

  describe 'handy event-based predicate methods' do
    context 'when the change is a create' do
      before { allow(paper_trail_version).to receive(:event).and_return('create') }

      its(:create?) { is_expected.to eq true }
      its(:update?) { is_expected.to eq false }
      its(:publish?) { is_expected.to eq false }
    end

    context 'when the change is a generic update' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object_changes).and_return({})
      end

      its(:create?) { is_expected.to eq false }
      its(:update?) { is_expected.to eq true }
      its(:publish?) { is_expected.to eq false }
    end

    context 'when the change is a publish (special case of update)' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'aasm_state' => [
            WorkVersion::STATE_DRAFT,
            WorkVersion::STATE_PUBLISHED
          ]
        )
      end

      its(:create?) { is_expected.to eq false }
      its(:update?) { is_expected.to eq false }
      its(:publish?) { is_expected.to eq true }
    end
  end
end
