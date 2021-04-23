# frozen_string_literal: true

module NullObjectPattern
  extend ActiveSupport::Concern

  def respond_to_missing?(_name, _include_private)
    nil
  end

  def method_missing(_name, *_args)
    nil
  end

  def nil?
    true
  end
  alias :blank? :nil?
  alias :empty? :nil?
end
