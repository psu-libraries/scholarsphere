# frozen_string_literal: true

require 'rails_helper'

describe 'migration' do
  before(:all) { Rails.application.load_tasks }

  after { Rake::Task['migration:statistics'].reenable }

  describe ':statistics' do
    let(:csv) { Pathname.new(fixture_path).join('s3_export_stats.csv') }

    context 'when the work is published' do
      before { create(:legacy_identifier, old_id: 'tb09j581r', resource: create(:work, has_draft: false)) }

      it 'imports view statistics from Scholarsphere 3' do
        expect {
          Rake::Task['migration:statistics'].invoke(csv)
        }.to change(ViewStatistic, :count).by(4)
      end
    end

    context 'when the work is not published' do
      before { create(:legacy_identifier, old_id: 'tb09j581r', resource: create(:work, has_draft: true)) }

      it 'imports view statistics from Scholarsphere 3' do
        expect {
          Rake::Task['migration:statistics'].invoke(csv)
        }.not_to change(ViewStatistic, :count)
      end
    end

    context 'with files' do
      before { create(:legacy_identifier, :with_file, old_id: 'rxw42n8719') }

      it 'imports view statistics from Scholarsphere 3' do
        expect {
          Rake::Task['migration:statistics'].invoke(csv)
        }.to change(ViewStatistic, :count).by(3)
      end
    end
  end
end
