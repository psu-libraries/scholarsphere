# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scholarsphere::Migration::Resource, type: :model do
  describe 'table' do
    subject { described_class }

    its(:column_names) do
      is_expected.to include(
        'pid',
        'model',
        'client_status',
        'client_message',
        'exception',
        'error',
        'started_at',
        'completed_at'
      )
    end
  end

  describe 'validations' do
    context 'when pid and model are missing' do
      subject { described_class.new }

      it { is_expected.not_to be_valid }
    end

    context 'when pid and model are provided' do
      subject { described_class.new(pid: '1234', model: 'GenericWork') }

      it { is_expected.to be_valid }
    end
  end

  describe '#migrated?' do
    context 'when the resource has been successfully published' do
      subject { described_class.new(client_status: 200) }

      it { is_expected.to be_migrated }
    end

    context 'when the resource has been migrated but not published' do
      subject { described_class.new(client_status: 201) }

      it { is_expected.to be_migrated }
    end

    context 'when an error is encountered' do
      subject { described_class.new(client_status: 422) }

      it { is_expected.not_to be_migrated }
    end
  end

  describe '#failed?' do
    context 'when the client returns an unsuccessful response' do
      subject { described_class.new(client_status: 422) }

      it { is_expected.to be_failed }
    end
  end

  describe '#blocked?' do
    context 'when a local error occurs' do
      subject { described_class.new(exception: 'ArgumentError') }

      it { is_expected.to be_blocked }
    end
  end

  describe '#message' do
    context 'when there is a client message' do
      subject { described_class.new(pid: '1234', model: 'GenericWork', client_message: "{\"message\": \"success!\"}") }

      its(:message) { is_expected.to eq('message' => 'success!') }
      its(:message) { is_expected.to be_a(HashWithIndifferentAccess) }
    end

    context 'when there is no client message' do
      subject { described_class.new(pid: '1234', model: 'GenericWork') }

      its(:message) { is_expected.to be_empty }
    end
  end

  describe '#migrate' do
    let(:success) { Faraday::Response.new(status: 200, body: '{"message": "success!"}') }

    context 'when the resource has not been migrated' do
      let(:resource) { described_class.new(pid: '1234', model: 'GenericWork') }

      it 'calls the export service' do
        expect(Scholarsphere::Migration::ExportService).to receive(:call).with('1234').and_return(success)
        resource.migrate
        expect(resource.client_status).to eq('200')
        expect(resource.client_message).to eq("{\"message\": \"success!\"}")
        expect(resource.started_at).not_to be_nil
        expect(resource.completed_at).not_to be_nil
      end
    end

    context 'when the resource has already been migrated' do
      let(:resource) { described_class.new(pid: '1234', model: 'GenericWork', client_status: 200) }

      it 'does not call the export service' do
        expect(Scholarsphere::Migration::ExportService).not_to receive(:call).with('1234')
        expect { resource.migrate }.not_to(change { resource })
      end
    end

    context 'when forcing a re-migration' do
      let(:resource) { described_class.new(pid: '1234', model: 'GenericWork', client_status: 200) }

      it 'calls the export service' do
        expect(Scholarsphere::Migration::ExportService).to receive(:call).with('1234')
        expect { resource.migrate(force: true) }.to change(resource, :updated_at)
      end
    end

    context 'when the migration raises an error' do
      subject(:resource) { described_class.new(pid: '1234', model: 'GenericWork') }

      before do
        allow(Scholarsphere::Migration::ExportService)
          .to receive(:call)
          .with('1234')
          .and_raise(StandardError, "oops, something went wrong!#{'x' * 300}")
        resource.migrate
      end

      its(:exception) { is_expected.to eq('StandardError') }
      its(:error) { is_expected.to match(/^oops, something went wrong!x{220}\.\.\.$/) }
      its(:completed_at) { is_expected.not_to be_nil }
    end
  end

  describe '#duration' do
    context 'when the migration has not been run' do
      subject { described_class.new }

      its(:duration) { is_expected.to eq(0) }
    end

    context 'with recorded times' do
      subject { described_class.new(started_at: start_time, completed_at: (start_time + 5.seconds)) }

      let(:start_time) { DateTime.now }

      its(:duration) { is_expected.to eq(5) }
    end
  end
end
