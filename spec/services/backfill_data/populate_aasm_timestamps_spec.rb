# frozen_string_literal: true

require 'rails_helper'
require 'shrine/storage/memory'

RSpec.describe BackfillData::PopulateAasmTimestamps, type: :model, versioning: true do
  subject(:call_service) { described_class.call }

  let(:external_app) { create :external_app }

  # Some boilerplate required to have minio not complain to us about creating files in the distant past
  before(:context) do
    Shrine.storages = {
      cache: Shrine::Storage::Memory.new,
      store: Shrine::Storage::Memory.new
    }
  end

  after(:context) do
    Shrine.storages = Scholarsphere::ShrineConfig.storages
  end

  # Note that I am using instance vars (`@work`) instead of the preferred
  # `let(:work)` syntax here because I need exact control over when and where
  # these records are created
  before do
    Timecop.freeze noon('2022-02-01') do
      @draft = create(:work_version, :draft)
    end

    Timecop.freeze noon('2022-02-02') do
      @published = create(:work_version, :able_to_be_published)
    end

    Timecop.freeze noon('2022-02-03') do
      @published.publish!
    end

    Timecop.freeze noon('2022-02-04') do
      @published.withdraw!
    end

    Timecop.freeze noon('2022-02-05') do
      @published_by_external_app = create(:work, versions_count: 1, has_draft: false, deposited_at: noon('2022-01-01'))
        .versions
        .first
      @published_by_external_app.update(external_app: external_app)
    end
  end

  it 'migrates any timestamps from papertrail publish events to the correct timestamp fields' do
    call_service

    @draft.reload.tap do |d|
      expect(d.published_at).to be_nil
      expect(d.withdrawn_at).to be_nil
      expect(d.removed_at).to be_nil
    end

    @published.reload.tap do |p|
      expect(p.published_at).to be_within(1.second).of(noon('2022-02-03'))
      expect(p.withdrawn_at).to be_within(1.second).of(noon('2022-02-04'))
      expect(p.removed_at).to be_nil
    end

    @published_by_external_app.reload.tap do |pbea|
      expect(pbea.published_at).to be_within(1.second).of(noon('2022-01-01'))
      expect(pbea.withdrawn_at).to be_nil
      expect(pbea.removed_at).to be_nil
    end
  end

  def noon(date_str)
    Date.parse(date_str).noon
  end
end
