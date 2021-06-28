# frozen_string_literal: true

# @abstract Returns or yields a set of FileResource objects based on their mime types.
#
# Examples
#
# Return a set of file resources for a given mime type
#
#   resources = FindByMimeType.call(mime_types: 'image/png')
#
# Return a set of file resources for a set of mime types
#
#   resources = FindByMimeType.call(mime_types: ['image/png', 'image/jpeg'])
#
# Iterate over all text-based file resources. This is helpful when needing to batch process a large set of files
#
#   FindByMimeType.call(mime_types: :text) do |resource|
#     resource.update(...)
#   end
#

class FindByMimeType
  TEXT = %w(
    application/msword
    application/pdf
    application/postscript
    application/rtf
    application/vnd.ms-excel
    application/vnd.oasis.opendocument.spreadsheet
    application/vnd.oasis.opendocument.text
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.wordperfect
    application/x-mobipocket-ebook
    html
    text
    xml
  ).freeze

  class << self
    def call(mime_types: [])
      types = mime_types == :text ? TEXT : Array.wrap(mime_types)
      sql = build_statement(types)

      ActiveRecord::Base
        .connection
        .execute(sql)
        .values
        .flatten
        .map do |id|
          FileResource.find(id) do |resource|
            block_given? ? yield(resource) : resource
          end
        end
    end

    private

      def build_statement(types)
        inner_sql = types.map do |type|
          "file_data->'metadata'->>'mime_type' LIKE '%#{type}%'"
        end.join("\n            OR    ")

        %(
        SELECT DISTINCT
          file_version_memberships.file_resource_id
        FROM
          file_version_memberships
        WHERE
          file_version_memberships.work_version_id IN (
            SELECT id
            FROM work_versions
            WHERE aasm_state = 'published'
          )
        AND
          file_version_memberships.file_resource_id IN (
            SELECT id
            FROM file_resources
            WHERE #{inner_sql}
          )
        )
      end
  end
end
