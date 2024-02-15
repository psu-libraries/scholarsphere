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

  describe '#save' do
    let(:context) { double }

    before do
      allow(wv).to receive(:save).with(context: context).and_return true
      allow(wv).to receive(:attributes=)
    end

    context "when the form's work version is valid" do
      context 'when the form is valid' do
        it "assigns the form's attributes to the form's work version" do
          form.save(context: context)
          expect(wv).to have_received(:attributes=).with(form.attributes).at_least(:once)
        end

        it "saves the form's work version" do
          form.save(context: context)
          expect(wv).to have_received(:save).with(context: context)
        end

        context 'when the work version saves successfully' do
          it 'returns true' do
            expect(form.save(context: context)).to eq true
          end
        end
      end

      context 'when the form is not valid' do
        before { form.description = nil }

        it 'returns nil' do
          expect(form.save(context: context)).to be_nil
        end

        it 'does not persist the form data' do
          form.save(context: context)
          expect(wv).not_to have_received(:save)
        end

        it 'sets errors on the form' do
          form.save(context: context)
          expect(form.errors[:description]).not_to be_empty
        end
      end
    end

    context "when the form's work version is invalid" do
      let(:valid) { false }
      let(:errors) { { version_name: 'not a valid version name' } }

      context 'when the form is valid' do
        it "assigns the form's attributes to the form's work version" do
          form.save(context: context)
          expect(wv).to have_received(:attributes=).with(form.attributes)
        end

        it "transfers the work version's errors on the form" do
          form.save(context: context)
          expect(form.errors[:version_name]).to include 'not a valid version name'
        end

        it 'does not persist the form data' do
          form.save(context: context)
          expect(wv).not_to have_received(:save)
        end

        it 'returns false' do
          expect(form.save(context: context)).to eq false
        end
      end

      context 'when the form is not valid' do
        before { form.description = nil }

        it "assigns the form's attributes to the form's work version" do
          form.save(context: context)
          expect(wv).to have_received(:attributes=).with(form.attributes).at_least(:once)
        end

        it 'sets errors on the form' do
          form.save(context: context)
          expect(form.errors[:description]).not_to be_empty
        end

        it "transfers the work version's errors on the form" do
          form.save(context: context)
          expect(form.errors[:version_name]).to include 'not a valid version name'
        end

        it 'does not persist the form data' do
          form.save(context: context)
          expect(wv).not_to have_received(:save)
        end

        it 'returns false' do
          expect(form.save(context: context)).to eq false
        end
      end
    end
  end
end
