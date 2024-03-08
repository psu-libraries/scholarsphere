# frozen_string_literal: true

shared_examples_for 'a work deposit pathway form' do
  it { is_expected.to delegate_method(:id).to(:work_version) }
  it { is_expected.to delegate_method(:to_param).to(:work_version) }
  it { is_expected.to delegate_method(:persisted?).to(:work_version) }
  it { is_expected.to delegate_method(:uuid).to(:work_version) }
  it { is_expected.to delegate_method(:new_record?).to(:work_version) }
  it { is_expected.to delegate_method(:published?).to(:work_version) }
  it { is_expected.to delegate_method(:draft?).to(:work_version) }
  it { is_expected.to delegate_method(:work).to(:work_version) }
  it { is_expected.to delegate_method(:work_type).to(:work_version) }
  it { is_expected.to delegate_method(:draft_curation_requested).to(:work_version) }

  describe '#indexing_source=' do
    before { allow(wv).to receive(:indexing_source=) }

    let(:arg) { double }

    it 'delegates to the given work version' do
      form.indexing_source = arg
      expect(wv).to have_received(:indexing_source=).with(arg)
    end
  end

  describe '#update_doi=' do
    before { allow(wv).to receive(:update_doi=) }

    let(:arg) { double }

    it 'delegates to the given work version' do
      form.update_doi = arg
      expect(wv).to have_received(:update_doi=).with(arg)
    end
  end

  describe '.model_name' do
    it 'returns a WorkVersion model name object' do
      expect(described_class.model_name).to eq WorkVersion.model_name
    end
  end
end
