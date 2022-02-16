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
      md5
      sha256
      downloads
    ]
  end

  def rows
    downloads_by_file_resource_id = load_downloads

    file_version_memberships.find_each do |fvm|
      file_resource = fvm.file_resource
      work_version = fvm.work_version

      title = fvm.title.presence || file_resource.file.metadata['filename']
      downloads = downloads_by_file_resource_id[file_resource.id] || 0

      row = [
        file_resource.uuid,
        work_version.uuid,
        title,
        file_resource.file.metadata['mime_type'],
        file_resource.file.metadata['size'],
        file_resource.file.metadata['md5'],
        file_resource.file.metadata['sha256'],
        downloads
      ]

      yield row
    end
  end

  private

    def file_version_memberships
      FileVersionMembership
        .includes(:file_resource, :work_version)
    end

    def load_downloads
      ViewStatistic
        .where(resource_type: 'FileResource')
        .group(:resource_id)
        .sum(:count)
    end
end
