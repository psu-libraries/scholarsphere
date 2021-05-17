# frozen_string_literal: true

RSpec.shared_examples 'a resource with a generated uuid' do
  before do
    raise 'resource must be set with `let(:resource)`' unless defined? resource

    resource.uuid = nil
  end

  it { is_expected.to have_db_column(:uuid).of_type(:uuid) }

  it "reloads the resource when it's first saved" do
    expect(resource.uuid).to be_nil
    resource.save
    expect(resource.uuid).to match(/[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/)
  end
end
