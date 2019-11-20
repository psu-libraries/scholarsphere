# frozen_string_literal: true

class DiffPresenter
  def initialize(diff)
    diff.map do |key, value|
      hash[key] = Diffy::Diff.new(*value)
    end
  end

  def terms
    hash.keys
  end

  def hash
    @hash ||= ActiveSupport::HashWithIndifferentAccess.new
  end

  delegate :[], to: :hash
end
