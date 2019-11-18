# frozen_string_literal: true

RSpec.shared_examples 'a multivalued json field' do |field|
  subject { described_class.new(field => ['', 'thing']) }

  its(field) { is_expected.to contain_exactly('thing') }
end
