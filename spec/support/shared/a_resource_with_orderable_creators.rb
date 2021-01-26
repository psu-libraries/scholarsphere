# frozen_string_literal: true

RSpec.shared_examples 'a resource with orderable creators' do
  before(:all) do
    raise 'resource must be set with `let(:resource)`' unless defined? resource
  end

  it 'orders them by #position asc' do
    creator_a, creator_b = resource.creators

    creator_a.update!(alias: 'A', position: 1)
    creator_b.update!(alias: 'B', position: 2)

    resource.reload
    expect(resource.creators.map(&:alias)).to eq %w(A B)

    creator_a.update!(position: 100)

    resource.reload
    expect(resource.creators.map(&:alias)).to eq %w(B A)
  end
end
