# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TitleSchema, type: :schema do
  let(:schema) { described_class.new(resource: resource) }

  describe '#document' do
    context 'when the title has stopwords' do
      subject { schema.document[:title_ssort] }

      let(:resource) { create(:work_version, title: 'The Curious Case of Benjamin Button') }

      it { is_expected.to eq('curious case of benjamin button the') }
    end

    context 'when the title has punctuation' do
      subject { schema.document[:title_ssort] }

      let(:resource) { create(:work_version, title: "\"...The play's the thing.\": Shakespeare's 1601 Hamlet") }

      it { is_expected.to eq('plays the thing shakespeares 1601 hamlet the') }
    end
  end
end
