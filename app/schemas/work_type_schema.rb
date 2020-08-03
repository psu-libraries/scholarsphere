# frozen_string_literal: true

class WorkTypeSchema < BaseSchema
  def document
    {
      display_work_type_ssi: Work::Types.display(resource.work_type),
      work_type_ss: resource.work_type
    }
  end

  def reject
    [:work_type_tesim, :resource_type_tesim]
  end
end
