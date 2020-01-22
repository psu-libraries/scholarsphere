# frozen_string_literal: true

require 'spec_helper'
require 'data_cite'

RSpec.describe DoiService do
  subject(:call_service) { described_class.call(resource) }

  let(:client_mock) { instance_spy 'DataCite::Client' }
  let(:metadata_mock) { instance_spy 'DataCite::Metadata' }

  before do
    allow(DataCite::Client).to receive(:new).and_return(client_mock)
    allow(DataCite::Metadata).to receive(:new).and_return(metadata_mock)
  end

  describe '.call' do
    context 'when given a WorkVersion' do
      let(:resource) { work_version }
      let(:work_version) { FactoryBot.build_stubbed :work_version }

      before do
        allow(resource).to receive(:update!)
        allow(resource).to receive(:valid?).and_return(true)
      end

      context "when the WorkVersion's doi field is empty" do
        before { work_version.doi = nil }

        context 'when the WorkVersion is DRAFT' do
          before { allow(work_version).to receive(:draft?).and_return(true) }

          it 'registers a new doi' do
            call_service
            expect(client_mock).to have_received(:register)
          end

          it 'saves the doi on the WorkVersion db record' do
            allow(client_mock).to receive(:register).and_return(['new/doi', { some: :metadata }])
            call_service
            expect(work_version).to have_received(:update!).with(doi: 'new/doi')
          end
        end

        context 'when the WorkVersion is PUBLISHED' do
          before do
            allow(work_version).to receive(:draft?).and_return(false)
            allow(work_version).to receive(:published?).and_return(true)
          end

          it 'publishes a new doi with metadata' do
            allow(metadata_mock).to receive(:attributes).and_return(mocked: :metadata)
            call_service
            expect(DataCite::Metadata).to have_received(:new).with(
              work_version: work_version,
              public_identifier: work_version.uuid
            )
            expect(client_mock).to have_received(:publish).with(
              doi: nil,
              metadata: { mocked: :metadata }
            )
          end

          it 'saves the doi on the WorkVersion db record' do
            allow(client_mock).to receive(:publish).and_return(['new/doi', { some: :metadata }])
            call_service
            expect(work_version).to have_received(:update!).with(doi: 'new/doi')
          end
        end
      end

      context "when the WorkVersion's doi field is present" do
        before { work_version.doi = 'existing/doi' }

        context 'when the WorkVersion is DRAFT' do
          before { allow(work_version).to receive(:draft?).and_return(true) }

          it 'does nothing' do
            call_service
            expect(client_mock).not_to have_received(:register)
            expect(client_mock).not_to have_received(:publish)
          end
        end

        context 'when the WorkVersion is PUBLISHED' do
          before do
            allow(work_version).to receive(:draft?).and_return(false)
            allow(work_version).to receive(:published?).and_return(true)
          end

          it 'publishes the doi with metadata' do
            allow(metadata_mock).to receive(:attributes).and_return(mocked: :metadata)
            call_service
            expect(DataCite::Metadata).to have_received(:new).with(
              work_version: work_version,
              public_identifier: work_version.uuid
            )
            expect(client_mock).to have_received(:publish).with(
              doi: 'existing/doi',
              metadata: { mocked: :metadata }
            )
          end

          it 'does not update the WorkVerison db record' do
            call_service
            expect(work_version).not_to have_received(:update!)
          end
        end
      end
    end

    context 'when given a Work' do
      let(:resource) { work }
      let(:work) { FactoryBot.build_stubbed :work }
      let(:latest_work_version) { FactoryBot.build_stubbed :work_version, work: work }

      before do
        allow(work).to receive(:latest_version).and_return(latest_work_version)
        allow(work).to receive(:update!)
        allow(work).to receive(:valid?).and_return(true)
      end

      context "when the Work's doi field is empty" do
        before { work.doi = nil }

        context "when the work's latest version is a DRAFT version" do
          before { allow(latest_work_version).to receive(:draft?).and_return(true) }

          it 'registers a new doi' do
            call_service
            expect(client_mock).to have_received(:register)
          end

          it 'saves the doi on the Work db record' do
            allow(client_mock).to receive(:register).and_return(['new/doi', { some: :metadata }])
            call_service
            expect(work).to have_received(:update!).with(doi: 'new/doi')
          end
        end

        context "when the work's latest version is a PUBLISHED verison" do
          before do
            allow(latest_work_version).to receive(:draft?).and_return(false)
            allow(latest_work_version).to receive(:published?).and_return(true)
          end

          it 'publishes a new doi with metadata' do
            allow(metadata_mock).to receive(:attributes).and_return(mocked: :metadata)
            call_service
            expect(DataCite::Metadata).to have_received(:new).with(
              work_version: latest_work_version,
              public_identifier: work.uuid
            )
            expect(client_mock).to have_received(:publish).with(
              doi: nil,
              metadata: { mocked: :metadata }
            )
          end

          it 'saves the doi on the Work db record' do
            allow(client_mock).to receive(:publish).and_return(['new/doi', { some: :metadata }])
            call_service
            expect(work).to have_received(:update!).with(doi: 'new/doi')
          end
        end
      end

      context "when the Work's doi field is present" do
        before { work.doi = 'existing/doi' }

        context "when the work's latest version is a DRAFT version" do
          before { allow(latest_work_version).to receive(:draft?).and_return(true) }

          it 'does nothing' do
            call_service
            expect(client_mock).not_to have_received(:register)
            expect(client_mock).not_to have_received(:publish)
          end
        end

        context "when the work's latest version is a PUBLISHED verison" do
          before do
            allow(latest_work_version).to receive(:draft?).and_return(false)
            allow(latest_work_version).to receive(:published?).and_return(true)
          end

          it 'publishes the doi with metadata' do
            allow(metadata_mock).to receive(:attributes).and_return(mocked: :metadata)
            call_service
            expect(DataCite::Metadata).to have_received(:new).with(
              work_version: latest_work_version,
              public_identifier: work.uuid
            )
            expect(client_mock).to have_received(:publish).with(
              doi: 'existing/doi',
              metadata: { mocked: :metadata }
            )
          end

          it 'does not update the Work db record' do
            call_service
            expect(work).not_to have_received(:update!)
          end
        end
      end
    end

    context 'when given some other type of object' do
      let(:resource) { FactoryBot.build_stubbed :user }

      it { expect { call_service }.to raise_error(ArgumentError) }
    end

    context 'when given an invalid resource' do
      let(:resource) { instance_spy('Work', valid?: false) }

      it do
        expect {
          call_service
        }.to raise_error(described_class::Error)
      end
    end

    context 'when the metadata mapper cannot build valid metadata' do
      let(:resource) { FactoryBot.build_stubbed :work_version, doi: nil }

      before do
        allow(resource).to receive(:draft?).and_return(false)
        allow(metadata_mock).to receive(:validate!).and_raise(DataCite::Metadata::ValidationError)
      end

      it do
        expect {
          call_service
        }.to raise_error(DataCite::Metadata::ValidationError)
      end
    end

    context 'when the doi client raises an error' do
      let(:resource) { FactoryBot.build_stubbed :work_version, doi: nil }

      before do
        allow(resource).to receive(:draft?).and_return(true)
        allow(client_mock).to receive(:register).and_raise(DataCite::Client::Error)
      end

      it do
        expect {
          call_service
        }.to raise_error(DataCite::Client::Error)
      end
    end
  end
end
