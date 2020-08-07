# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorMailer, type: :mailer do
  let(:actor) { build(:actor) }

  describe '#monthly_stats' do
    context 'when the actor has NO file downloads' do
      subject { described_class.with(actor: actor).monthly_stats }

      its(:message) { is_expected.to be_a(ActionMailer::Base::NullMail) }
    end

    context 'when the actor has file downloads' do
      let(:mail) { described_class.with(actor: actor).monthly_stats }
      let(:mock_presenter) { ActorStatsPresenter.new(actor: actor) }

      before do
        allow(ActorStatsPresenter).to receive(:new).with(any_args).and_return(mock_presenter)
        allow(mock_presenter).to receive(:file_downloads).and_return(3)
      end

      it "sends an email with the depositor's monthly download statistics" do
        expect(mail.subject).to eq('ScholarSphere - Reporting Monthly Downloads and Views')
        expect(mail.to).to contain_exactly(actor.email)
        expect(mail.body.raw_source).to match(/You had 3 new downloads last month across your 0 files/)
      end
    end
  end
end
