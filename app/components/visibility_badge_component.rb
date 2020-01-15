# frozen_string_literal: true

require 'action_view/component'

class VisibilityBadgeComponent < ActionView::Component::Base
  validates :work,
            presence: true

  # @param [Work, SolrDocument]
  def initialize(work:)
    @work = work
  end

  private

    attr_reader :work

    def html_class
      [
        'badge',
        'visibility',
        "visibility--#{visibility}"
      ].join(' ')
    end

    def image_class
      [
        'visibility'
      ].join(' ')
    end

    def visibility
      work.visibility || Permissions::Visibility::PRIVATE
    end

    def image_source
      details[visibility][:image]
    end

    def label
      details[visibility][:label]
    end

    def details
      {
        Permissions::Visibility::OPEN => {
          label: 'Open Access',
          image: 'visibility-open.png'
        },
        Permissions::Visibility::AUTHORIZED => {
          label: 'Penn State',
          image: 'visibility-authorized.png'
        },
        Permissions::Visibility::PRIVATE => {
          label: 'Restricted',
          image: 'visibility-private.png'
        }
      }
    end
end
