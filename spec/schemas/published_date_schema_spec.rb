# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishedDateSchema do
  subject(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    subject(:document) { schema.document }

    context 'when the resource has a valid EDTF published date' do
      let(:resource) { build(:work_version, published_date: '2019?') }

      before do
        allow(EdtfDate::SolrDateRangeFormatter)
          .to receive(:format)
          .with('2019?')
          .and_return('[1998 TO 2000]')
      end

      it { is_expected.to eq(published_date_dtrsi: '[1998 TO 2000]') }
    end

    context 'when the resoruce has an invalid published date' do
      let(:resource) { build(:work_version, published_date: 'not-a-date') }

      before do
        allow(EdtfDate)
          .to receive(:valid?)
          .with('not-a-date')
          .and_return(false)
      end

      it { is_expected.to be_empty }
    end

    context 'when the resource does not have creators' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      it { is_expected.to be_empty }
    end
  end
end
