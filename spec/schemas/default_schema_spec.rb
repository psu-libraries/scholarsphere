# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DefaultSchema do
  context 'with a WorkVersion' do
    let(:resource) { WorkVersion }

    describe '#schema' do
      subject(:schema) { described_class.new(resource).schema }

      its(:keys) { is_expected.not_to include('id', 'metadata') }
      it { is_expected.to include('title_tesim' => ['title']) }
      it { is_expected.to include('keyword_tesim' => ['keyword']) }
      it { is_expected.to include('created_at_dtsi' => ['created_at']) }
      it { is_expected.to include('updated_at_dtsi' => ['updated_at']) }
      it { is_expected.to include('uuid_ssi' => ['uuid']) }
      it { is_expected.to include('aasm_state_tesim' => ['aasm_state']) }
      it { is_expected.to include('work_id_isi' => ['work_id']) }
    end
  end
end
