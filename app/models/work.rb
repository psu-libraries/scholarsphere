# frozen_string_literal: true

class Work < ApplicationRecord
  belongs_to :depositor,
             class_name: 'User',
             foreign_key: 'depositor_id',
             inverse_of: 'works'

  module Types
    DATASET = 'dataset'

    def self.all
      [DATASET]
    end

    def self.display(type)
      type.humanize.titleize
    end

    def self.options_for_select_box
      all
        .sort
        .map { |type| [display(type), type] }
    end
  end

  validates :work_type,
            presence: true,
            inclusion: { in: Types.all }
end
