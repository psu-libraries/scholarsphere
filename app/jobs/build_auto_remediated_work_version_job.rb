# frozen_string_literal: true

class BuildAutoRemediatedWorkVersionJob < ApplicationJob
  queue_as :auto_remediation

  def perform(file_resource_id, remediated_file_url)
    file_resource = FileResource.find(file_resource_id)

    BuildAutoRemediatedWorkVersion.call(file_resource, remediated_file_url)
  end
end
