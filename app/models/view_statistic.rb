# frozen_string_literal: true

class ViewStatistic < ApplicationRecord
  belongs_to :resource, polymorphic: true
end
