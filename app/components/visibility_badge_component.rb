# frozen_string_literal: true

class VisibilityBadgeComponent < ApplicationComponent
  # @param [Work, SolrDocument]
  def initialize(work:)
    @work = work
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
          label: 'Open Access',
          color: 'orange',
          icon: 'lock_open'
        },
        Permissions::Visibility::AUTHORIZED => {
          label: 'Penn State',
          color: 'blue',
          icon: 'pets'
        },
        Permissions::Visibility::PRIVATE => {
          label: 'Restricted',
          color: 'red',
          icon: 'lock'
        }
      }
    end
end
