# frozen_string_literal: true

class AutopopulateWorkVersionService
  attr_accessor :work_version, :doi

  def initialize(work_version, doi)
    @work_version = work_version
    @doi = doi
  end

  def call
    work_version.attributes = rmd_pub_to_attributes
    work_version.save
  end

  private

    def rmd_pub_to_attributes
      {
        title: rmd_pub.title,
        description: rmd_pub.abstract,
        subtitle: rmd_pub.secondary_title,
        published_date: rmd_pub.published_on,
        keyword: rmd_pub.tags,
        creators: rmd_pub.contributors.map { |c| authorship(c) },
        publisher: [rmd_pub.publisher],
        identifier: [doi],
        related_url: [rmd_pub.preferred_open_access_url, rmd_pub.supplementary_url].compact
      }
    end

    def authorship(contributor)
      Authorship.new(
        position: contributor.position,
        given_name: contributor.first_name,
        surname: contributor.last_name,
        display_name: contributor.first_name +
                      (contributor.middle_name.present? ? " #{contributor.middle_name} " : ' ') +
                      contributor.last_name,
        email: contributor.psu_user_id.present? ? "#{contributor.psu_user_id}@psu.edu" : nil,
        actor: actor(contributor)
      )
    end

    def actor(contributor)
      return nil if contributor.psu_user_id.blank?

      actor = Actor.find_by(psu_id: contributor.psu_user_id)

      actor.presence || Actor.new(
        given_name: contributor.first_name,
        surname: contributor.last_name,
        display_name: contributor.first_name +
                      (contributor.middle_name.present? ? " #{contributor.middle_name} " : ' ') +
                      contributor.last_name,
        psu_id: contributor.psu_user_id,
        email: contributor.psu_user_id.present? ? "#{contributor.psu_user_id}@psu.edu" : nil
      )
    end

    def rmd_pub
      RmdPublication.new(doi)
    end
end
