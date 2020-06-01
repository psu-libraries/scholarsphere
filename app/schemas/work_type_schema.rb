# frozen_string_literal: true

class WorkTypeSchema < BaseSchema
  def document
    {
      work_type_ssim: Work::Types.display(resource.work_type)
    }
  end

  def reject
    [:work_type_tesim, :resource_type_tesim]
  end
end
