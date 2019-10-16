# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Uppy::S3Multipart::App, type: :request do
  describe 'POST' do
    subject { response }

    before { post '/s3/multipart' }

    it { is_expected.to be_successful }
  end
end
