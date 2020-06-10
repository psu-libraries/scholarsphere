# frozen_string_literal: true

RSpec.shared_examples 'an indexable resource' do
  it { is_expected.to respond_to(:update_index) }
  it { is_expected.to respond_to(:update_index_async) }
end
