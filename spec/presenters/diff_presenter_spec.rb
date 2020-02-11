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

    context 'with the same titles and different keywords' do
      let(:first) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'bar']) }
      let(:second) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'baz']) }

      it 'returns diffs each term' do
        expect(presenter[:title].to_s).to be_empty
        expect(presenter[:keyword].to_s).to eq(
          "-foo, bar\n\\ No newline at end of file\n+foo, baz\n\\ No newline at end of file\n"
        )
      end
    end

    context 'with a different number of values for the same term' do
      let(:first) { build(:work_version, title: 'The Same Title', keyword: ['foo', 'bar']) }
      let(:second) { build(:work_version, title: 'The Same Title', keyword: ['baz']) }

      it 'returns diffs that include the deleted term' do
        expect(presenter[:title].to_s).to be_empty
        expect(presenter[:keyword].to_s).to eq(
          "-foo, bar\n\\ No newline at end of file\n+baz\n\\ No newline at end of file\n"
        )
      end
    end
  end

  describe '#renamed_files' do
    let(:metadata_diff) { {} }

    context 'when no file diff is provided' do
      subject { described_class.new(metadata_diff) }

      its(:renamed_files) { is_expected.to be_empty }
    end

    context 'when the diff has renamed files' do
      let(:file_1) { build(:file_version_membership) }
      let(:file_2) { build(:file_version_membership) }

      let(:renamed_files) do
        described_class.new(
          metadata_diff,
          file_diff: { renamed: [[file_1, file_2]] }
        ).renamed_files
      end

      it 'returns an array of RenamedFile structs' do
        expect(renamed_files.first.title).to be_a(Diffy::Diff)
        expect(renamed_files.first.size).to eq(file_1.size)
        expect(renamed_files.first.mime_type).to eq(file_1.mime_type)
      end
    end
  end

  describe '#deleted_files' do
    let(:metadata_diff) { {} }

    context 'when no file diff is provided' do
      subject { described_class.new(metadata_diff) }

      its(:deleted_files) { is_expected.to be_empty }
    end

    context 'when the file diff has deleted files' do
      subject { described_class.new(metadata_diff, file_diff: file_diff) }

      let(:file_diff) { { deleted: ['deleted_file'] } }

      its(:deleted_files) { is_expected.to eq(['deleted_file']) }
    end
  end

  describe 'added_files' do
    let(:metadata_diff) { {} }

    context 'when no file diff is provided' do
      subject { described_class.new(metadata_diff) }

      its(:added_files) { is_expected.to be_empty }
    end

    context 'when the file diff has added files' do
      subject { described_class.new(metadata_diff, file_diff: file_diff) }

      let(:file_diff) { { added: ['added_file'] } }

      its(:added_files) { is_expected.to eq(['added_file']) }
    end
  end
end
