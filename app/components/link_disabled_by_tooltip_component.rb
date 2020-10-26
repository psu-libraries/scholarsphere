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

    def disabled?
      !enabled?
    end

    def html_options
      { class: classes }
        .deep_merge(tooltip_options)
        .deep_merge(link_options)
    end

    def classes
      klasses = Array.wrap(class_list).dup
      klasses << 'disabled' if disabled?
      klasses
    end

    def tooltip_options
      return {} if enabled?

      {
        data: {
          toggle: 'tooltip',
          placement: 'bottom'
        },
        title: tooltip
      }
    end

    def link_options
      return {} if disabled?

      { method: method }
    end

    def default_classes
      %w(btn btn-outline-light btn--squish mr-lg-2)
    end
end
