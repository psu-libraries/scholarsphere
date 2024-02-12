# frozen_string_literal: true

class EmbargoForm
  include ActiveModel::Model

  attr_reader :work

  attr_writer :embargoed_until
  attr_accessor :remove

  validate :embargoed_until_is_valid_date,
           unless: :remove?

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
    return false unless valid?

    work.embargoed_until = if remove?
                             nil
                           elsif embargoed_until.present?
                             Time.zone.parse(embargoed_until).beginning_of_day
                           end
    work.save
  end

  private

    def embargoed_until_is_valid_date
      return if embargoed_until.blank?

      unless /^\d{4}-\d{2}-\d{2}$/.match?(embargoed_until.to_s)
        errors.add(:embargoed_until, :format)
        return
      end

      begin
        Date.parse(embargoed_until.to_s)
        unless embargoed_until < (DateTime.now + 4.years)
          errors.add(:embargoed_until, :max)
          nil
        end
      rescue ArgumentError, TypeError
        errors.add(:embargoed_until, :not_a_date)
      end
    end
end
