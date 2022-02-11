# frozen_string_literal: true

class AllFilesReport
  def name
    'all_files'
  end

  def headers
    %w[
      id
      version_id
      filename
      mime_type
      size
      downloads
    ]
  end

  def rows
    file_version_memberships.in_batches do |fvm_batch|
      # Load out aggregates of downloads for this batch
      downloads_by_file_resource_id = load_downloads_by_file_resource(fvm_batch)

      # Iterate through each file_version_membership in this batch, yielding the CSV row
      fvm_batch.each do |fvm|
        downloads = downloads_by_file_resource_id[fvm.file_resource.id] || 0

        row = [
          fvm.file_resource.uuid,
          fvm.work_version.uuid,
          fvm.file_resource.file_data['metadata']['filename'],
          fvm.file_resource.file_data['metadata']['mime_type'],
          fvm.file_resource.file_data['metadata']['size'],
          downloads
        ]

        yield(row)
      end
    end
  end

  private
    def file_version_memberships
      FileVersionMembership
        .includes(:file_resource)
        .includes(:work_version)
    end

    def load_downloads_by_file_resource(fvm_batch)
      resource_ids = Set[]
      
      fvm_batch.each do |fvm|
        resource_ids << fvm.file_resource_id
      end

      resource_ids = resource_ids.to_a.join(', ')

      query = %{
        SELECT resource_id, sum(count)
        FROM view_statistics
        WHERE resource_type = 'FileResource'
        AND resource_id in (#{resource_ids})
        GROUP BY resource_id
      }

      results = ActiveRecord::Base.connection.execute(query)

      downloads_by_file_resource = {}
      
      results.each do |result|
        downloads_by_file_resource[result['resource_id']] = result['sum']
      end

      downloads_by_file_resource
    end
end
