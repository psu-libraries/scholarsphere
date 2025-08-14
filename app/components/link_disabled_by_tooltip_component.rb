# frozen_string_literal: true

class LinkDisabledByTooltipComponent < ApplicationComponent
  def initialize(enabled:, text:, path:, tooltip:, method: :get, class_list: nil)
    @enabled = !!enabled
    @text = text
    @path = path
    @tooltip = tooltip
    @method = method
    @class_list = class_list || default_classes
  end

  private

    attr_reader :enabled,
                :text,
                :path,
                :tooltip,
                :method,
                :class_list

    def enabled?
      enabled
    end

    def html_options_enabled
      {
        class: class_list,
        method: method
      }
    end

    def html_options_disabled
      classes = Array.wrap(class_list) + ['disabled']

      {
        class: classes,
        data: {
          bs_toggle: 'tooltip',
          bs_placement: 'bottom'
        },
        title: tooltip
      }
    end

    def default_classes
      %w(btn btn-outline-light btn--squish me-lg-2)
    end
end
