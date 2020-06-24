# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourcesController, type: :controller do
  describe '#show' do
    context 'when requesting a Work' do
      let(:work) { create(:work, has_draft: false) }

      it 'loads the Work' do
        get :show, params: { id: work.uuid }
        expect(assigns[:resource]).to eq work
      end

      it "inserts a view statistic record for the work's latest published version" do
        expect {
          get :show, params: { id: work.uuid }
        }.to change {
          ViewStatistic.where(resource_type: 'WorkVersion', resource_id: work.latest_published_version).count
        }.from(0).to(1)
      end
    end

    context 'when requesting a WorkVersion' do
      let(:work_version) { create :work_version }

      it 'loads the WorkVersion' do
        get :show, params: { id: work_version.uuid }
        expect(assigns[:resource]).to eq work_version
      end
    end

    context 'when requesting a Collection' do
      let(:collection) { create :collection }

      it 'loads the WorkVersion' do
        get :show, params: { id: collection.uuid }
        expect(assigns[:resource]).to eq collection
      end
    end

    context 'when requesting an unknown uuid' do
      it do
        expect {
          get :show, params: { id: 'not-a-valid-uuid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the resource is valid, but not publicly accessible' do
      let(:work) { create(:work, :with_no_access) }

      it do
        expect {
          get :show, params: { id: work.uuid }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when a bot is requesting the resource' do
      let(:work_version) { create :work_version }
      let(:bot) { Browser.new('Bot') }

      before { allow(controller).to receive(:browser).and_return(bot) }

      it 'does NOT add a statistic record for the resource' do
        expect {
          get :show, params: { id: work_version.uuid }
        }.not_to(
          change {
            ViewStatistic.where(resource_type: 'WorkVersion', resource_id: work_version).count
          }
        )
      end
    end
  end
end
