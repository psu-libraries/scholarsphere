# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoRemediationMailer do
  subject(:mailer) { described_class.with(contributor_email: 'contributor@example.com',
                                          work_title: 'Title of Work',
                                          work_version_uuid: '123e4567-e89b-12d3-a456-426614174000') }

  describe '#remediated_version_created' do
    it 'renders the remediated_version_created template' do
      mail = mailer.remediated_version_created

      expect(mail.subject).to eq('Accessible Version of Your Work Now Available on ScholarSphere')
      expect(mail.to).to contain_exactly('contributor@example.com')
      expect(mail.body.encoded).to include(
        "<a href=\"#{Rails.application.routes.url_helpers.root_url}resources/123e4567-e89b-12d3-a456-426614174000\">Title of Work</a>"
      )
      expect(mail.body.encoded).to include(
        'The Libraries’ Adaptive Technology and Services team will manually '
      )
    end
  end
end
