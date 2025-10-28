# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoRemediationMailer do
  subject(:mailer) { described_class.with(params) }

  let(:params) { { contributor_email: 'contributor@example.com',
                   work_title: 'Title of Work',
                   work_version_uuid: '123e4567-e89b-12d3-a456-426614174000' } }
  let(:mail) { mailer.remediated_version_created }

  describe '#remediated_version_created' do
    context 'when all required params are provided' do
      it 'renders the remediated_version_created template' do
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

    context 'when delivering the email' do
      context 'when a required param is missing' do
        let(:params) { { work_title: 'Title of Work',
                         work_version_uuid: '123e4567-e89b-12d3-a456-426614174000' } }

        it 'raises an error' do
          expect { mail.deliver_now }.to raise_error(KeyError)
        end
      end

      context 'when all required params are provided' do
        it 'sends the email successfully' do
          expect { mail.deliver_now }.not_to raise_error
        end
      end
    end
  end
end
