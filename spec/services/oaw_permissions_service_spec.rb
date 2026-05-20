# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OawPermissionsService do
  subject(:service) { described_class.new(doi) }

  let(:doi) { 'https://doi.org/10.1016/j.bmcl.2010.08.031' }

  let(:permissions) do
    [
      {
        'version' => 'acceptedVersion',
        'deposit_statement' => 'Accepted version statement',
        'embargo_end' => '2011-08-31',
        'licence' => 'cc-by-nc-nd'
      },
      {
        'version' => 'publishedVersion',
        'deposit_statement' => 'Published version statement',
        'embargo_end' => '2012-08-31',
        'licence' => 'cc-by'
      }
    ]
  end

  before do
    response = instance_double(
      Faraday::Response,
      body: { all_permissions: permissions }.to_json
    )

    allow(Faraday).to receive(:get).and_return(response)
  end

  describe '#initialize' do
    it 'strips the doi.org prefix' do
      expect(service.instance_variable_get(:@doi)).to eq('10.1016/j.bmcl.2010.08.031')
    end

    it 'accepts a DOI' do
      bare_service = described_class.new('10.1016/j.bmcl.2010.08.031')

      expect(bare_service.instance_variable_get(:@doi)).to eq('10.1016/j.bmcl.2010.08.031')
    end
  end

  describe '#publisher_statement' do
    it 'returns the deposit statement for the requested version' do
      expect(service.publisher_statement('acceptedVersion'))
        .to eq('Accepted version statement')
    end

    context 'when no statement exists' do
      let(:permissions) do
        [{
          'version' => 'acceptedVersion',
          'embargo_end' => '2011-08-31',
          'licence' => 'cc-by-nc-nd'
        }]
      end

      it 'returns nil' do
        expect(service.publisher_statement('acceptedVersion')).to be_nil
      end
    end

    context 'when the version is unknown' do
      it 'returns nil' do
        expect(service.publisher_statement('unknownVersion')).to be_nil
      end
    end
  end

  describe '#embargo_end_date' do
    it 'parses the embargo date' do
      expect(service.embargo_end_date('acceptedVersion'))
        .to eq(Date.new(2011, 8, 31))
    end

    context 'when no embargo end date exists' do
      let(:permissions) do
        [{
          'version' => 'acceptedVersion',
          'deposit_statement' => 'Accepted version statement',
          'licence' => 'cc-by-nc-nd'
        }]
      end

      it 'returns nil when no embargo end exists' do
        expect(service.embargo_end_date('acceptedVersion')).to be_nil
      end
    end

    context 'when the version is unknown' do
      it 'returns nil' do
        expect(service.embargo_end_date('unknownVersion')).to be_nil
      end
    end
  end

  describe '#licence' do
    it 'maps the licence to the corresponding rights URL' do
      expect(service.licence('acceptedVersion'))
        .to eq('https://creativecommons.org/licenses/by-nc-nd/4.0/')
    end

    context 'when the licence is not found' do
      let(:permissions) do
        [{
          'version' => 'acceptedVersion',
          'deposit_statement' => 'Accepted version statement',
          'embargo_end' => '2011-08-31'
        }]
      end

      it 'returns nil' do
        expect(service.licence('acceptedVersion')).to be_nil
      end
    end

    context 'when the licence is not recognized' do
      let(:permissions) do
        [{
          'version' => 'acceptedVersion',
          'deposit_statement' => 'Accepted version statement',
          'embargo_end' => '2011-08-31',
          'licence' => 'unknown-licence'
        }]
      end

      it 'returns nil' do
        expect(service.licence('acceptedVersion')).to be_nil
      end
    end
  end

  describe '#versions_found?' do
    context 'when multiple versions exist' do
      it 'returns all found versions' do
        expect(service.versions_found?)
          .to contain_exactly('acceptedVersion', 'publishedVersion')
      end
    end

    context 'when only accepted version exists' do
      let(:permissions) do
        [
          {
            'version' => 'acceptedVersion'
          }
        ]
      end

      it 'returns only acceptedVersion' do
        expect(service.versions_found?).to eq(['acceptedVersion'])
      end
    end

    context 'when no permissions exist' do
      before do
        response = instance_double(
          Faraday::Response,
          body: { all_permissions: nil }.to_json
        )

        allow(Faraday).to receive(:get).and_return(response)
      end

      it 'returns an empty array' do
        expect(service.versions_found?).to eq([])
      end
    end
  end

  describe '#current_version_found?' do
    context 'when the requested version exists' do
      it 'returns true' do
        expect(service.current_version_found?('acceptedVersion')).to be(true)
      end
    end

    context 'when the requested version does not exist' do
      it 'returns false' do
        expect(service.current_version_found?('submittedVersion')).to be(false)
      end
    end
  end

  describe '#permissions_found?' do
    context 'when permissions are present' do
      it 'returns true' do
        expect(service.permissions_found?).to be(true)
      end
    end

    context 'when permissions are absent' do
      before do
        response = instance_double(
          Faraday::Response,
          body: { all_permissions: nil }.to_json
        )

        allow(Faraday).to receive(:get).and_return(response)
      end

      it 'returns false' do
        expect(service.permissions_found?).to be(false)
      end
    end
  end
end
