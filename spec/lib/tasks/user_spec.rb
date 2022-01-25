# frozen_string_literal: true

require 'rails_helper'

describe 'User rake tasks', type: :task do
  describe ':monthly_stats_email', :inline_jobs do
    before { allow_any_instance_of(ActorStatsPresenter).to receive(:file_downloads).and_return(3) }

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
        before { create(:user, opt_out_stats_email: true) }

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

  describe ':update_active_statuses', :inline_jobs do
    let!(:user) { create(:user) }

    after { Rake::Task['user:update_active_statuses'].reenable }

    context 'when user is active faculty' do
      let(:response) do
        object_double(PsuIdentity::SearchService::Person.new,
                      affiliation: ['FACULTY', 'MEMBER'])
      end

      before do
        user.active = false
        user.save!
        allow_any_instance_of(PsuIdentity::SearchService::Client).to receive(:userid).and_return response
      end

      it 'updates user active status to true' do
        Rake::Task['user:update_active_statuses'].invoke
        user.reload
        expect(user.active).to eq true
      end
    end

    context 'when user is just a MEMBER' do
      let(:response) do
        object_double(PsuIdentity::SearchService::Person.new,
                      affiliation: ['MEMBER'])
      end

      before do
        allow_any_instance_of(PsuIdentity::SearchService::Client).to receive(:userid).and_return response
      end

      it 'updates user active status to false' do
        Rake::Task['user:update_active_statuses'].invoke
        user.reload
        expect(user.active).to eq false
      end
    end

    context 'when no user is found' do
      before do
        allow_any_instance_of(PsuIdentity::SearchService::Client)
          .to receive(:userid)
          .and_raise PsuIdentity::SearchService::NotFound
      end

      it 'updates user active status to false' do
        Rake::Task['user:update_active_statuses'].invoke
        user.reload
        expect(user.active).to eq false
      end
    end

    context 'when timeout occurs' do
      before do
        allow_any_instance_of(PsuIdentity::SearchService::Client).to receive(:userid).and_raise Net::ReadTimeout
      end

      it 'does not change user active status' do
        expect { Rake::Task['user:update_active_statuses'].invoke }.not_to change(user, :active)
      end
    end
  end
end
