# frozen_string_literal: true

require 'spec_helper'
require 'json_log_formatter'

RSpec.describe JSONLogFormatter do
  describe '#parse_message' do
    it 'acccepts a string' do
      # json = described_class.new
      msg = 'INFO'
      expect(described_class.new.parse_message(msg)).to eq(msg)
    end

    it 'returns an object when passed a json string' do
      msg = { "foo": 'bar' }.to_json
      expect(described_class.new.parse_message(msg)).to have_key('foo')
    end

    it 'returns an object if passed an object' do
      msg = { "foo": 'bar' }
      expect(described_class.new.parse_message(msg)).to eq(msg)
    end
  end

  describe '#call' do
    it 'returns a json string when passed hash' do
      msg = { "foo": 'bar' }
      expect(described_class.new.call('INFO', Time.now, 'foo', msg)).to be_a(String)
    end

    it 'returns a nested json object when passed a json-encodable string' do
      msg = { "foo": 'bar' }.to_json
      parsed_message = JSON.parse(described_class.new.call('INFO', Time.now, 'foo', msg))
      expect(parsed_message).to have_key('type')
      expect(parsed_message).to have_key('time')
      expect(parsed_message).to have_key('msg')
      expect(parsed_message['msg']).to have_key('foo')
    end

    it 'retains the message value as msg object when passed a string' do
      msg = 'This thing totally broke'
      parsed_message = JSON.parse(described_class.new.call('INFO', Time.now, 'foo', msg))
      expect(parsed_message['msg']).to eq(msg)
    end
  end
end
