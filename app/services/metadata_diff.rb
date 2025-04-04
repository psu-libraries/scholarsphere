# frozen_string_literal: true

# @abstract Returns a hash with the differences between two classes that contain a `metadata` json accessors.
# @example Given two objects with two different titles
#   >  MetadataDiff(obj1, obj2)
#   => { title: ["Object 1 Title", "Object 2 Title"] }
#
# Accessors that have the same values will be omitted from the diff hash
class MetadataDiff
  attr_reader :opts

  # @param [WorkVersion, Object]
  # @param [WorkVersion, Object]
  # @param [Hash] opts
  # @example opts[:separator] will concatenate multiple values together. Default is ", "
  def self.call(*)
    new(*).hash
  end

  def initialize(*args)
    @opts = args[2] || {}
    (args[0].metadata.keys + args[1].metadata.keys).uniq.map do |key|
      first_value = stringify(args[0].metadata[key])
      second_value = stringify(args[1].metadata[key])
      hash[key] = [first_value, second_value] unless first_value == second_value
    end
  end

  def hash
    @hash ||= ActiveSupport::HashWithIndifferentAccess.new
  end

  private

    def stringify(terms)
      Array.wrap(terms).join(separator)
    end

    def separator
      @separator ||= opts.fetch(:separator, ', ')
    end
end
