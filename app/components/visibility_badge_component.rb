# frozen_string_literal: true

class VisibilityBadgeComponent < ApplicationComponent
  # @param [Work, SolrDocument]
  def initialize(work:)
    @work = work
  end

  def render
    work.respond_to?(:visibility)
  end

  private

    attr_reader :work

    def html_class
      [
        'badge',
        'badge--icon',
        "badge--icon-#{details[visibility][:color]}"
      ].join(' ')
    end

    def visibility
      work.visibility || Permissions::Visibility::PRIVATE
    end

    def label
      details[visibility][:label]
    end

    def icon
      details[visibility][:icon]
    end

    def details
      {
        Permissions::Visibility::OPEN => {
          label: i18n_label(Permissions::Visibility::OPEN),
          color: 'orange',
          icon: 'lock_open'
        },
        Permissions::Visibility::AUTHORIZED => {
          label: i18n_label(Permissions::Visibility::AUTHORIZED),
          color: 'blue',
          icon: 'pets'
        },
        Permissions::Visibility::PRIVATE => {
          label: i18n_label(Permissions::Visibility::PRIVATE),
          color: 'red',
          icon: 'lock'
        }
      }
    end

    def i18n_label(key)
      I18n.t("visibility_badge_component.label.#{key}", raise: true)
    end
end
