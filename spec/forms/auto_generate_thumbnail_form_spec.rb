# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoGenerateThumbnailForm, type: :model do
  subject(:form) { described_class.new(resource: work, params: params) }

  let(:work) { create(:work, versions_count: 2, has_draft: true) }

  describe '#save' do
    let(:params) { { auto_generate_thumbnail: true } }

    it 'updates work' do
      expect {
        form.save
      }.to change {
        work.reload.auto_generate_thumbnail
      }.from(false).to(true)
    end
  end
end
