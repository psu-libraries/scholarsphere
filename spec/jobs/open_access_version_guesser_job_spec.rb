# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessVersionGuesserJob do
  subject(:job) { described_class.new }

  let!(:work_version) { create(:work_version, open_access_version: nil) }
  let(:guessed_version) { OpenAccessVersion::VersionValues::PUBLISHED }
  let(:guesser) { instance_double('OpenAccessVersionGuesser', version: guessed_version) }
  let(:guesser_class) { class_double('OpenAccessVersionGuesser').as_stubbed_const }

  describe '#perform' do
    before do
      allow(guesser_class).to receive(:new).with(work_version: work_version).and_return(guesser)
    end

    it 'guesses the open access version and updates the work version' do
      job.perform(work_version.id)

      expect(guesser_class).to have_received(:new).with(work_version: work_version)
      expect(work_version.reload.open_access_version).to eq guessed_version
    end

    context 'when the guesser returns nil' do
      let(:guessed_version) { nil }

      it 'persists nil as the open access version' do
        job.perform(work_version.id)

        expect(work_version.reload.open_access_version).to be_nil
      end
    end
  end

  describe 'sidekiq options' do
    it 'uses the default queue' do
      expect(described_class.get_sidekiq_options['queue']).to eq(:default)
    end
  end
end
