# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionViewStatsCache do
  let(:session) { double('session', id: 1) }
  let(:another_session) { double('session', id: 2) }
  let(:work) { build_stubbed(:work, id: 1) }
  let(:collection) { build_stubbed(:collection, id: 1) }

  before(:all) do
    redis = Redis.new(Rails.configuration.redis)
    redis.keys('vs:*').each { |key| redis.del(key) }
  end

  it 'retuns false if the given session/resource combo is in the cache already' do
    expect(described_class.call(session: session, resource: work)).to eq true
    expect(described_class.call(session: session, resource: work)).to eq false

    expect(described_class.call(session: session, resource: collection)).to eq true
    expect(described_class.call(session: session, resource: collection)).to eq false

    expect(described_class.call(session: another_session, resource: work)).to eq true
    expect(described_class.call(session: another_session, resource: collection)).to eq true
  end
end
