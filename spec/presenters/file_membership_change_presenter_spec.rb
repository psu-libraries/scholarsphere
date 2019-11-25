# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileMembershipChangePresenter do
  subject(:presenter) { described_class.new(
    paper_trail_version: paper_trail_version,
    user: user
  ) }

  let(:paper_trail_version) do
    instance_spy 'PaperTrail::Version',
                 item_type: 'FileVersionMembership',
                 object_changes: nil
  end

  let(:user) { instance_spy 'User' }

  it { is_expected.to delegate_method(:created_at).to(:paper_trail_version) }
  it { is_expected.to delegate_method(:event).to(:paper_trail_version) }
  it { is_expected.to delegate_method(:id).to(:paper_trail_version) }

  describe '#initialize' do
    context 'when the given PaperTrail::Version does not apply to a FileVersionMembership' do
      before { allow(paper_trail_version).to receive(:item_type).and_return('SomeOtherClass') }

      it { expect { presenter }.to raise_error(ArgumentError) }
    end
  end

  describe '#to_partial_path' do
    it { expect(presenter.to_partial_path).to eq 'file_membership_change' }
  end

  describe '#action' do
    subject { presenter.action }

    before do
      allow(paper_trail_version).to receive(:event).and_return(event)
    end

    context 'when created' do
      let(:event) { 'create' }

      it { is_expected.to eq I18n.t('dashboard.work_history.file_membership.create') }
    end

    context 'when destroyed' do
      let(:event) { 'destroy' }

      it { is_expected.to eq I18n.t('dashboard.work_history.file_membership.destroy') }
    end

    context 'when renamed (a special case of update)' do
      let(:event) { 'update' }

      before do
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'title' => %w(old new)
        )
      end

      it { is_expected.to eq I18n.t('dashboard.work_history.file_membership.rename') }
    end

    context 'when generically updated (unlikely scenario)' do
      let(:event) { 'update' }

      it { is_expected.to eq 'Updated' }
    end
  end

  describe '#current_filename' do
    subject { presenter.current_filename }

    context 'when created' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('create')
        allow(paper_trail_version).to receive(:object).and_return(nil)
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'title' => [nil, 'the_current_filename']
        )
      end

      it { is_expected.to eq 'the_current_filename' }
    end

    context 'when updated' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object).and_return(
          'title' => 'the_old_filename'
        )
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'title' => ['the_old_filename', 'the_current_filename']
        )
      end

      it { is_expected.to eq 'the_current_filename' }
    end

    context 'when destroyed' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('destroy')
        allow(paper_trail_version).to receive(:object).and_return(
          'title' => 'the_current_filename'
        )
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'title' => ['the_current_filename', nil]
        )
      end

      it { is_expected.to eq 'the_current_filename' }
    end
  end

  describe '#previous_filename' do
    subject { presenter.previous_filename }

    context 'when updated' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object).and_return(
          'title' => 'the_old_filename'
        )
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'title' => ['the_old_filename', 'the_current_filename']
        )
      end

      it { is_expected.to eq 'the_old_filename' }
    end

    context 'when some other event' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('create')
      end

      it { is_expected.to eq nil }
    end
  end

  describe '#timestamp' do
    let(:created_at) { Time.zone.parse('2019-10-21 15:10:00') }

    before { allow(paper_trail_version).to receive(:created_at).and_return(created_at) }

    it "returns a human-friendly version of the papertrail's #created_at" do
      expect(presenter.timestamp).to eq 'October 21, 2019 15:10'
    end
  end

  describe '#rename?' do
    subject { presenter.rename? }

    context 'when renamed (a special case of update)' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
        allow(paper_trail_version).to receive(:object_changes).and_return(
          'title' => %w(old new)
        )
      end

      it { is_expected.to eq true }
    end

    context 'when generically updated (unlikely scenario)' do
      before do
        allow(paper_trail_version).to receive(:event).and_return('update')
      end

      it { is_expected.to eq false }
    end
  end
end
