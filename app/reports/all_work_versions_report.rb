# frozen_string_literal: true

class AllWorkVersionsReport
  def name
    'all_work_versions'
  end

  def headers
    %w[
      id
      work_id
      state
      version_number
      title
      subtitle
      version_name
      keyword
      rights
      description
      publisher_statement
      resource_type
      contributor
      publisher
      published_date
      subject
      language
      identifier
      based_near
      related_url
      source
      owner
      manufacturer
      model
      instrument_type
      measured_variable
      available_date
      decommission_date
      related_identifier
      alternative_identifier
      instrument_resource_type
      funding_reference
      sub_work_type
      program
      degree
      views
    ]
  end

  def rows
    work_versions.find_in_batches do |work_versions|
      # Load out aggregates of views for this batch
      work_version_batch_ids = work_versions.map(&:id)
      views_by_work_version_id = load_views_by_work_version(work_version_batch_ids)

      # Iterate through each work version in this batch, yielding the CSV row
      work_versions.each do |wv|
        views = views_by_work_version_id[wv.id] || 0

        row = [
          wv.uuid,
          wv.work.uuid,
          wv.aasm_state,
          wv.version_number,
          wv.title,
          wv.subtitle,
          wv.version_name,
          wv.keyword,
          wv.rights,
          wv.description,
          wv.publisher_statement,
          wv.resource_type,
          wv.contributor,
          wv.publisher,
          wv.published_date,
          wv.subject,
          wv.language,
          wv.identifier,
          wv.based_near,
          wv.related_url,
          wv.source,
          wv.owner,
          wv.manufacturer,
          wv.model,
          wv.instrument_type,
          wv.measured_variable,
          wv.available_date,
          wv.decommission_date,
          wv.related_identifier,
          wv.alternative_identifier,
          wv.instrument_resource_type,
          wv.funding_reference,
          wv.sub_work_type,
          wv.program,
          wv.degree,
          views
        ]

        yield(row)
      end
    end
  end

  private

    def work_versions
      WorkVersion
        .includes(:work)
        .order('work_id, id asc')
    end

    # Returns a hash of { work_version_id => num_views }
    def load_views_by_work_version(work_version_batch)
      ViewStatistic
        .where(
          resource_type: 'WorkVersion',
          resource_id: work_version_batch
        )
        .group('resource_id')
        .sum(:count)
    end
end
