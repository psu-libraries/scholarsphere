# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataDiff do
  subject(:diff) { described_class.call(first, second) }

  let(:first) { build(:work_version) }
  let(:second) { build(:work_version) }

  it { is_expected.to be_a(ActiveSupport::HashWithIndifferentAccess) }

  context 'when the titles are different' do
    its(:keys) { is_expected.to include('title') }

    it 'returns a diff of the titles' do
      expect(diff[:title]).to eq([first.title, second.title])
    end
  end

  context 'with the same titles and different keywords' do
    let(:first) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'bar']) }
    let(:second) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'baz']) }

    its(:keys) { is_expected.to include('keyword') }

    it 'returns only the terms that are different' do
      expect(diff[:title]).to be_nil
      expect(diff[:keyword]).to eq(['foo, bar', 'foo, baz'])
    end
  end

  context 'with a different number of values for the same term' do
    let(:first) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'bar']) }
    let(:second) { build(:work_version, title: 'The Same Title', keyword: ['baz']) }

    its(:keys) { is_expected.to include('keyword') }

    it 'returns diffs that include the deleted term' do
      expect(diff[:title]).to be_nil
      expect(diff[:keyword]).to eq(['foo, bar', 'baz'])
    end
  end

  context 'with a custom separator' do
    subject(:diff) { described_class.call(first, second, separator: '; ') }

    let(:first) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'bar']) }
    let(:second) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'baz']) }

    it 'shows the diff with the separator' do
      expect(diff[:keyword]).to eq(['foo; bar', 'foo; baz'])
    end
  end
end
