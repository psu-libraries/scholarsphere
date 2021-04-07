# frozen_string_literal: true

RSpec.shared_examples 'a resource that can provide all DOIs in' do |fields_with_dois|
  its(:fields_with_dois) { is_expected.to match_array fields_with_dois }
  its(:all_dois) { is_expected.to be_a Array }
end
