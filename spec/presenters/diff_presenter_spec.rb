# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiffPresenter do
  subject(:presenter) { described_class.new(MetadataDiff.call(first, second)) }

  let(:first) { build(:work_version) }
  let(:second) { build(:work_version) }

  describe '#terms' do
    its(:terms) { is_expected.to contain_exactly('title') }
  end

  describe '#hash' do
    its(:hash) { is_expected.to be_a(ActiveSupport::HashWithIndifferentAccess) }
  end

  describe '#[]' do
    context 'when the titles are different' do
      it 'returns a diff of the titles' do
        expect(presenter[:title]).to be_a(Diffy::Diff)
      end
    end

    context 'with the same titles and different keyworks' do
      let(:first) { build(:work_version, title: 'The Same Title', keywords: ['foo', 'bar']) }
      let(:second) { build(:work_version, title: 'The Same Title', keywords: ['foo', 'baz']) }

      it 'returns diffs each term' do
        expect(presenter[:title].to_s).to be_empty
        expect(presenter[:keywords].to_s).to eq(
          "-foo, bar\n\\ No newline at end of file\n+foo, baz\n\\ No newline at end of file\n"
        )
      end
    end

    context 'with a different number of values for the same term' do
      let(:first) { build(:work_version, title: 'The Same Title', keywords: ['foo', 'bar']) }
      let(:second) { build(:work_version, title: 'The Same Title', keywords: ['baz']) }

      it 'returns diffs that include the deleted term' do
        expect(presenter[:title].to_s).to be_empty
        expect(presenter[:keywords].to_s).to eq(
          "-foo, bar\n\\ No newline at end of file\n+baz\n\\ No newline at end of file\n"
        )
      end
    end
  end
end
