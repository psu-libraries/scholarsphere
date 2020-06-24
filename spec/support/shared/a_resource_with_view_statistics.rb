# frozen_string_literal: true

RSpec.shared_examples 'a resource with view statistics' do
  before do
    raise 'resource must be set with `let(:perform_request)`' unless defined? resource
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
end
