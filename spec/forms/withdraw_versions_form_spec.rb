# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawVersionsForm, type: :model do
  subject(:form) { described_class.new(work: work, params: params) }

  let(:params) { {} }

  let(:work) { create(:work, versions_count: 2, has_draft: true) }
  let(:work_version) { work.versions.first }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:work_version_id) }
  end

  describe '#version_options' do
    it 'renders all PUBLISHED versions for select box' do
      # Note that the work has two versions but v2 is a draft
      expect(form.version_options).to eq([['V1', work_version.id]])
    end
  end

  describe '#save' do
    context 'when no work_version_id present' do
      let(:params) { {} }

      it 'returns false' do
        expect(form.save).to be(false)
      end
    end

    context 'when there is a work_version_id present' do
      let(:params) { { work_version_id: work_version.id } }

      it 'withdraws the work version' do
        expect {
          form.save
        }.to change {
          work_version.reload.withdrawn?
        }.from(false).to(true)
      end
    end
  end
end
