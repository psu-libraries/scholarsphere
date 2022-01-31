# frozen_string_literal: true

class WithdrawVersionsForm
  include ActiveModel::Model

  attr_reader :work
  attr_accessor :work_version_id

  validates :work_version_id,
            presence: true

  def initialize(work:, params:)
    @work = work
    super(params)
  end

  def version_options
    work.versions.published
      .map { |version| [WorkVersionDecorator.new(version).display_version_short, version.id] }
  end

  def save
    return false unless valid?

    work_version.withdraw!
  end

  private

    def work_version
      work.versions.published.find(work_version_id)
    end
end
