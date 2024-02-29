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
    work_embargoed_until = if work.embargoed_until.respond_to?(:strftime)
                             work.embargoed_until.strftime('%Y-%m-%d')
                           end
    @embargoed_until || work_embargoed_until
  end

  def remove?
    !!ActiveModel::Type::Boolean.new.cast(remove)
  end

  def save
    work.embargoed_until = if remove?
      nil
    elsif embargoed_until.present?
      Time.zone.parse(embargoed_until).beginning_of_day
    end

    unless work.valid?
      work.errors[:embargoed_until].each do |error|
        errors.add(:embargoed_until, error)
      end
      return false
    end

    work.save
  end
end
