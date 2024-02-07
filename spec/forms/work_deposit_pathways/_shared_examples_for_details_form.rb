# frozen_string_literal: true

shared_examples_for 'a work deposit pathway details form' do
  it { is_expected.to delegate_method(:id).to(:work_version) }
  it { is_expected.to delegate_method(:to_param).to(:work_version) }
  it { is_expected.to delegate_method(:persisted?).to(:work_version) }
  it { is_expected.to delegate_method(:uuid).to(:work_version) }
  it { is_expected.to delegate_method(:new_record?).to(:work_version) }
  it { is_expected.to delegate_method(:published?).to(:work_version) }
  it { is_expected.to delegate_method(:draft?).to(:work_version) }
  it { is_expected.to delegate_method(:work).to(:work_version) }

  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:published_date) }
  it { is_expected.to allow_value('1999-uu-uu').for(:published_date) }
  it { is_expected.not_to allow_value('not an EDTF formatted date').for(:published_date) }

  describe '#indexing_source=' do
    let(:arg) { double }

    it 'delegates to the given work version' do
      form.indexing_source = arg
      expect(wv).to have_received(:indexing_source=).with(arg)
    end
  end

  describe '#update_doi=' do
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
