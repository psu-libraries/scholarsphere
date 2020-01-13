# frozen_string_literal: true

class LdapGroupCleaner
  class Error < RuntimeError; end

  class << self
    def call(ldap_record)
      call!(ldap_record)
    rescue Error
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
  end
end
