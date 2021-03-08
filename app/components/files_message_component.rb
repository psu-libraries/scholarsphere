# frozen_string_literal: true

class FilesMessageComponent < ApplicationComponent
  attr_reader :work_version

  # @param [WorkVersion]
  def initialize(work_version:)
    @work_version = work_version
  end

  private

    def download?
      Pundit.policy(controller.current_user, work_version).download?
    end

    # @deprecated This can be removed in 4.4.0
    def display_sharable_link?
      return false unless work_version.published?

      controller.controller_name == 'work_versions'
    end
end
