# frozen_string_literal: true

class EmbargoForm
  include ActiveModel::Model

  attr_reader :work

  attr_writer :embargoed_until
  attr_accessor :remove

  def initialize(work:, params:)
    @work = work
    super(params)
  end

  def embargoed_until
    return work.embargoed_until if @embargoed_until.blank?

    parsed_embargo_date
  end

  def remove?
    !!ActiveModel::Type::Boolean.new.cast(remove)
  end

  def save
    work.embargoed_until = if remove?
                             nil
                           elsif embargoed_until.present?
                             parsed_embargo_date
                           end

    unless work.valid?
      work.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      return false
    end

    work.save
  end

  private

    def parsed_embargo_date
      Time.zone.parse(@embargoed_until).beginning_of_day
    end
end
