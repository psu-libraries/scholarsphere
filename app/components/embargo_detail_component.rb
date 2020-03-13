# frozen_string_literal: true

require 'action_view/component'

class EmbargoDetailComponent < ActionView::Component::Base
  validates :work_version,
            presence: true

  attr_reader :work_version

  # @param [WorkVersion]
  # @todo We can avoid raising errors on unembargoed works with `render?` when it becomes available.
  def initialize(work_version:)
    raise ArgumentError, 'component must be used with an embargoed work' unless work_version.embargoed?

    @work_version = work_version
  end

  private

    def embargo_release_date
      work_version.work.embargoed_until.strftime('%Y-%m-%d')
    end

    def download?
      Pundit.policy(controller.current_user, work_version).download?
    end

    def display_sharable_link?
      return false unless work_version.published?

      controller.controller_name == 'work_versions'
    end
end
