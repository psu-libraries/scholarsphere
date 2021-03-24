# frozen_string_literal: true

class DoiSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:all_dois)

    {
      all_dois_ssim: resource.all_dois
    }
  end
end
