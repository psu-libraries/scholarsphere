# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembershipDecorator do
  subject(:decorator) { described_class.new(file_version_membership) }

  describe '#file_version_download_url' do
    let(:file_version_membership) { create(:file_version_membership) }

    it 'returns the download url for the file version' do
      expect(decorator.file_version_download_url).to eq(
        Rails.application.routes.url_helpers.resource_download_url(
          file_version_membership.id,
          resource_id: file_version_membership.work_version.uuid
        )
      )
    end
  end
end
