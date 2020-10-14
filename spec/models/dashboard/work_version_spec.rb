# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkVersion, type: :model do
  describe '::table_name' do
    subject { described_class.table_name }

    it { is_expected.to eq(::WorkVersion.table_name) }
  end

  describe '::model_name' do
    subject { described_class.model_name }

    it { is_expected.to eq(::WorkVersion.model_name) }
  end

  describe '.to_solr' do
    subject { dashboard_work_version.to_solr }

    let(:dashboard_work_version) { create(:dashboard_work_version, :published, :with_complete_metadata) }

    it { is_expected.to include('model_ssi' => 'WorkVersion') }
  end
end
