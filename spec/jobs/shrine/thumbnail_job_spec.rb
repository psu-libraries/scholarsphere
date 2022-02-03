# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shrine::ThumbnailJob, type: :job do
  let(:record) { build(:file_resource, :pdf) }

  context 'with valid input' do

    it 'creates derivatives' do
      described_class.perform_now(record)
      expect(record.file_attacher.url(:thumbnail)).to include("thumbnails")
    end
  end
end
