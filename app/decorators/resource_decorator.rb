# frozen_string_literal: true

class ResourceDecorator < SimpleDelegator
  def partial_name
    model_name.singular
  end

  def display_work_type
    return unless respond_to?(:work_type)

    Work::Types.display(work_type)
  end

  def display_published_date
    return unless respond_to?(:published_date)

    EdtfDate.humanize(published_date)
  end
end
