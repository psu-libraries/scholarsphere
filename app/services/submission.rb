# frozen_string_literal: true

require 'airrecord'

class Submission < Airrecord::Table
  self.base_key = ENV['AIRTABLE_BASE_KEY']
  self.table_name = ENV['AIRTABLE_TABLE_NAME']
end