# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/services/ldap_group_cleaner'

RSpec.describe LdapGroupCleaner do
  describe '.call' do
    let(:call) { described_class.call(input) }

    context 'with the happy path' do
      let(:input) { 'cn=umg/up.dlt.scholarsphere-admin.admin,dc=psu,dc=edu' }

      it 'returns the parsed group name' do
        expect(call).to eq 'umg/up.dlt.scholarsphere-admin.admin'
      end
    end

    context 'with a value that would raise an error to .call! (see below)' do
      let(:input) { 'cn=i have spaces,dc=psu,dc=edu' }
      let(:mock_logger) { instance_spy 'Proc' }

      before { @old_logger = described_class.logger_source }

      after { described_class.logger_source = @old_logger }

      it 'traps the error and returns nil' do
        expect(call).to be_nil
      end

      it 'logs the error' do
        described_class.logger_source = mock_logger
        call
        expect(mock_logger).to have_received(:call)
          .with(a_string_matching(input))
      end
    end
  end

  describe '.call!' do
    context 'with valid ldap records' do
      it 'returns the parsed group name' do
        expect(described_class.call!('cn=psu.up.staff,dc=psu,dc=edu')).to eq 'psu.up.staff'
        expect(described_class.call!('cn=umg/psu.aws.aws.304225443749.administrator,dc=psu,dc=edu'))
          .to eq 'umg/psu.aws.aws.304225443749.administrator'
      end
    end

    context 'with an ldap record with spaces' do
      let(:call!) { described_class.call!('cn=cn with spaces,dc=psu,dc=edu') }

      it { expect { call! }.to raise_error(described_class::Error) }
    end

    context 'with an ldap record with no group' do
      let(:call!) { described_class.call!('cn=,dc=psu,dc=edu') }

      it { expect { call! }.to raise_error(described_class::Error) }
    end

    context 'with an ldap record with invalid formatting' do
      let(:call!) { described_class.call!('invalid formatting') }

      it { expect { call! }.to raise_error(described_class::Error) }
    end
  end
end
