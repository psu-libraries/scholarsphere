# frozen_string_literal: true

RSpec.shared_examples 'a singlevalued json field' do |field|
  subject { described_class.new(field => '') }

  its(field) { is_expected.to be_nil }
end
