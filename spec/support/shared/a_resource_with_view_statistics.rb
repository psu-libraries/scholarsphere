# frozen_string_literal: true

RSpec.shared_examples 'a resource with view statistics' do
  let(:stat_loader_class) { LoadViewStatistics }

  before do
    raise 'resource must be set with `let(:resource)`' unless defined? resource
  end

  describe '#count_view!' do
    specify do
      expect {
        resource.count_view!
      }.to change {
        ViewStatistic.where(resource: resource).count
      }.from(0).to(1)
    end
  end

  describe '#stats' do
    before { allow(stat_loader_class).to receive(:call).and_return(:returned_stats) }

    specify do
      expect(resource.stats).to eq :returned_stats
      expect(stat_loader_class).to have_received(:call).with(model: resource)

      # This is a hack to get a nicer spec output message. I want it to say `it
      # "delegates to #{stat_loader_class}"` but rspec doesn't allow this, and
      # there's no other way to pass stat_loader_class into this shared example.
      expect(stat_loader_class).to eq stat_loader_class
    end
  end
end
