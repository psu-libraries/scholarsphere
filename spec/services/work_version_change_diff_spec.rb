# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionChangeDiff, versioning: true do
  subject(:diff) { described_class.call(last_paper_trail_version) }

  let(:work_version) { create :work_version }

  # Note, you must update work_version in some way in a before block
  let(:last_paper_trail_version) { work_version.reload.versions.last }

  context 'when the titles are different' do
    before do
      work_version.update!(title: 'An old title')
      work_version.update!(title: 'A new updated title')
    end

    its(:keys) { is_expected.to contain_exactly('title') }

    it 'returns a diff of the titles' do
      expect(diff[:title]).to eq(['An old title', 'A new updated title'])
    end
  end

  context 'with the same titles and different keywords' do
    before do
      work_version.update!(title: 'The Same Title', keywords: %w(foo bar))
      work_version.update!(title: 'The Same Title', keywords: %w(foo baz))
    end

    its(:keys) { is_expected.to contain_exactly('keywords') }

    it 'returns only the terms that are different' do
      expect(diff[:title]).to be_nil
      expect(diff[:keywords]).to eq(['foo, bar', 'foo, baz'])
    end
  end

  context 'with a different number of values for the same term' do
    before do
      work_version.update!(keywords: %w(foo bar))
      work_version.update!(keywords: %w(baz))
    end

    its(:keys) { is_expected.to contain_exactly('keywords') }

    it 'returns diffs that include the deleted term' do
      expect(diff[:keywords]).to eq(['foo, bar', 'baz'])
    end
  end

  context 'with a custom separator' do
    subject(:diff) { described_class.call(last_paper_trail_version, separator: '; ') }

    before do
      work_version.update!(keywords: %w(foo bar))
      work_version.update!(keywords: %w(foo baz))
    end

    it 'shows the diff with the separator' do
      expect(diff[:keywords]).to eq(['foo; bar', 'foo; baz'])
    end
  end
end
