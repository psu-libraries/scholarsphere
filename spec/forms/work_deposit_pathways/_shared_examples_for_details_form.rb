# frozen_string_literal: true

shared_examples_for 'a work deposit pathway details form' do
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:published_date) }
  it { is_expected.to allow_value('1999-uu-uu').for(:published_date) }
  it { is_expected.not_to allow_value('not an EDTF formatted date').for(:published_date) }

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

        it 'returns false' do
          expect(form.save(context: context)).to eq false
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
      before do
        wv.errors.add(:description, 'bad data!')
        allow(wv).to receive(:valid?).and_return false
      end

      context 'when the form is valid' do
        it "assigns the form's attributes to the form's work version" do
          form.save(context: context)
          expect(wv).to have_received(:attributes=).with(form.attributes)
        end

        it "transfers the work version's errors to the form" do
          form.save(context: context)
          expect(form.errors[:description]).to include 'bad data!'
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

        it "transfers the work version's errors to the form" do
          form.save(context: context)
          expect(form.errors[:description]).to include 'bad data!'
        end

        context 'when the work version and the form have the same validation error' do
          let(:description) { nil }

          before do
            wv.errors.clear
            allow(wv).to receive(:valid?).and_call_original
            wv.publish
            form.description = nil
          end

          it 'does not duplicate transferred errors' do
            form.save(context: context)
            expect(form.errors[:description].size).to eq 1
          end
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
