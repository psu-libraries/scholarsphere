# frozen_string_literal: true

RSpec.shared_examples 'a singlevalued json field' do |field|
  it 'converts "" to nil' do
    record = described_class.new(field => '')
    expect(record[field]).to be_nil
  end

  it 'allows the field to be cleared when it already has a value' do
    record = described_class.new(field => '123')
    record.update(field => '')
    expect(record[field]).to be_nil
  end
end
