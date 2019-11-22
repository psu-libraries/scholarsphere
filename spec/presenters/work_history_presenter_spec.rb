# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkHistoryPresenter, versioning: true do
  let(:presenter) { described_class.new(work) }

  let(:user) { create :user }

  let(:work) { create :work, versions: [draft, v1], depositor: user }

  let(:draft) { build :work_version, :draft, title: 'Draft', work: nil, created_at: 1.day.ago }
  let(:v1) { build :work_version, :published, title: 'Published v1', work: nil, created_at: 3.days.ago }

  # This is done in the controller, but we need to do it here to get our user on
  # the changes above
  before do
    PaperTrail.request.whodunnit = user.id
  end

  describe '#latest_work_version' do
    it 'returns a decorated version of the latest work version' do
      latest = presenter.latest_work_version
      expect(latest).to be_a(Dashboard::WorkVersionDecorator)
      expect(latest.title).to eq work.latest_version.title
    end
  end

  describe '#changes_by_work_version' do
    subject(:changes_by_work_version) { presenter.changes_by_work_version }

    it 'returns a 2d array, where dimension 1 is the versions of the given work' do
      keys = changes_by_work_version.to_h.keys
      expect(keys).to all(be_a(Dashboard::WorkVersionDecorator))
      expect(keys.map(&:title)).to contain_exactly('Draft', 'Published v1')
    end

    it 'returns a 2d array, where dimension 2 is the changes to each version, mapped to Presenter objects' do
      _version, changes = changes_by_work_version.first
      expect(changes).not_to be_empty
      expect(changes).to all(be_a(WorkVersionChangePresenter))

      # Spot check that one presenter is instantiated correctly
      changes.first.tap do |change|
        expect(change.user).to eq user
      end
    end

    context 'when the PaperTrail::Version `whodunnit` user cannot be found' do
      before do
        PaperTrail.request.whodunnit = nil
      end

      it 'provides a null-object User model to the presenters' do
        _version, changes = changes_by_work_version.first

        changes.first.tap do |change|
          expect(change.user.id).to be_nil
          expect(change.user).to be_readonly
        end
      end
    end
  end
end
