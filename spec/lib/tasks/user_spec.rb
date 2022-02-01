# frozen_string_literal: true

require 'rails_helper'

describe 'User rake tasks', type: :task do
  describe ':monthly_stats_email', :inline_jobs do
    before do
      allow_any_instance_of(ActorStatsPresenter).to receive(:file_downloads).and_return(3)
      allow(UpdateUserActiveStatuses).to receive(:call).and_return nil
    end

    after { Rake::Task['user:monthly_stats_email'].reenable }

    context 'with an active user' do
      context 'when they have opted to receive emails' do
        before { create(:user) }

        it 'sends an email to the user' do
          expect {
            Rake::Task['user:monthly_stats_email'].invoke
          }.to change(ActionMailer::Base.deliveries, :count).by(1)
        end
      end

      context 'when they have opted NOT to receive emails' do
        before { create(:user, opt_in_stats_email: false) }

        it 'does NOT send an email to the user' do
          expect {
            Rake::Task['user:monthly_stats_email'].invoke
          }.not_to(change(ActionMailer::Base.deliveries, :count))
        end
      end
    end

    context 'with an inactive user' do
      before { create(:user, active: false) }

      it 'does NOT send an email to the user' do
        expect {
          Rake::Task['user:monthly_stats_email'].invoke
        }.not_to(change(ActionMailer::Base.deliveries, :count))
      end
    end
  end
end
