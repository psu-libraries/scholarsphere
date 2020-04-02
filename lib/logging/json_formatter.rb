# frozen_string_literal: true

require 'json'

class JSONFormatter
  def parse_message(message)
    begin
      msg = JSON.parse(message)
    rescue JSON::ParserError
      msg = message
    end
    msg
  end

  def call(severity, timestamp, _progname, message)
    msg = {
      type: severity,
      time: timestamp,
      msg: parse_message(message)
    }.to_json
    "#{msg} \n"
  end
end
