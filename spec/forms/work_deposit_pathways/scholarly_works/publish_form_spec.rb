# frozen_string_literal: true

require 'rails_helper'
require_relative '../_shared_examples_for_work_deposit_pathway_form'

RSpec.describe WorkDepositPathway::ScholarlyWorks::PublishForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) { build(:work_version) }

  describe '#form_partial' do
    it 'returns scholarly_works_work_version' do
      expect(form.form_partial).to eq 'scholarly_works_work_version'
    end
  end

  describe 'open access version mismatch' do
    before { allow(wv).to receive(:published?).and_return(true) }

    it 'assigns the version mismatch field without assigning it to the work version' do
      form.attributes = { open_access_version_mismatched: 'true' }

      expect(form.open_access_version_mismatched).to eq 'true'
    end

    context 'when the selected version does not match the available permissions' do
      before { form.open_access_version_mismatched = 'true' }

      it 'adds an open access version error' do
        form.valid?

        expect(form.errors[:open_access_version]).to include('does not match the available permissions')
      end
    end

    context 'when the selected version matches the available permissions' do
      before { form.open_access_version_mismatched = 'false' }

      it 'does not add an open access version error' do
        form.valid?

        expect(form.errors[:open_access_version]).not_to include('does not match the available permissions')
      end
    end
  end
end
