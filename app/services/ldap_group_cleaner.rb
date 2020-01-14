# frozen_string_literal: true

class LdapGroupCleaner
  class Error < RuntimeError; end

  class << self
    attr_writer :logger_source

    def call(ldap_record)
      call!(ldap_record)
    rescue Error => e
      logger_source.call("#{e.class}: #{e.message.inspect} with record #{ldap_record.inspect}")
      nil
    end

    def call!(ldap_record)
      _cn, value = ldap_record
        .split(',')
        .map { |str| str.split('=') }
        .find { |key, _v| key == 'cn' }

      raise Error.new('LDAP group cannot contain spaces') if value.to_s.match?(/\s/)
      raise Error.new('LDAP group is empty') if value.to_s.empty?

      value
    end

    def logger_source
      @logger_source ||= ->(msg) { Rails.logger.error(msg) }
    end
  end
end
