# frozen_string_literal: true

# @note This could be replaced with an alternate view of WorkVersionMetadataComponent once multiple views are supported
# in ViewComponent. See https://github.com/github/view_component/tree/multiple-templates
class FeaturedWorkMetadataComponent < WorkVersionMetadataComponent
  private

    def attributes_list
      [
        :creators,
        :keyword
      ]
    end
end
