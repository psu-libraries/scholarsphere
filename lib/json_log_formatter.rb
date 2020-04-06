# frozen_string_literal: true

require 'json'

class JSONLogFormatter
  def parse_message(message)
    JSON.parse(message)
  rescue JSON::ParserError, TypeError
    message
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
