# frozen_string_literal: true

RSpec.shared_examples 'a report' do 
  it { is_expected.to respond_to :headers}
  it { is_expected.to respond_to :name}
  it { is_expected.to respond_to :rows}
end
