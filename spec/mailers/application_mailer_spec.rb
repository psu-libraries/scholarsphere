# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailer do
  describe '#default' do
    let(:default) { described_class.default }

    specify do
      expect(default[:from]).to eq('no_reply@scholarsphere.psu.edu')
    end
  end
end
