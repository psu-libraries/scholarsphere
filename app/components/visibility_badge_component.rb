# frozen_string_literal: true

class VisibilityBadgeComponent < ApplicationComponent
  # @param [Work, SolrDocument]
  def initialize(work:)
    @work = work
  end

  def render
    work.respond_to?(:visibility) && work.respond_to?(:embargoed?)
  end

  private

    attr_reader :work

    def label
      details[details_key][:label]
    end

    def color
      details[details_key][:color]
    end

    def icon
      details[details_key][:icon]
    end

    def html_class
      [
        'badge',
        'badge--icon',
        "badge--icon-#{color}"
      ].join(' ')
    end

    def tooltip
      return unless work.embargoed?

      I18n.t('visibility_badge_component.tooltip.embargoed', date: embargo_release_date)
    end

    def details_key
      return 'embargoed' if work.embargoed?

      work.visibility || Permissions::Visibility::PRIVATE
    end

    def details
      {
        'embargoed' => {
          label: i18n_label('embargoed'),
          color: 'red',
          icon: 'lock_clock'
        },
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

    def embargo_release_date
      work.embargoed_until.strftime('%Y-%m-%d')
    end
end
