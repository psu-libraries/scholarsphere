# frozen_string_literal: true

namespace :curation do
  desc 'Sync curation tasks'
  task sync: :environment do
    works = Work.recently_published
    works.each do |work|
      CurationSyncService.sync(work.id)
      sleep(0.5)
    end
  end
end
