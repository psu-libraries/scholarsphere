# frozen_string_literal: true

class DiffPresenter
  # @note OpenStruct representing the renamed file. The title is a Diffy::Diff so we can show what parts of the title
  # changed, but it also includes the size and mime type so we can display it like any other file.
  class RenamedFile < OpenStruct; end

  attr_reader :files,
              :creators

  # @param [Hash] output from MetadataDiff.call
  # @param [Hash, nil] output from WorkVersionMembershipDiff.call
  # @param [Hash, nil] output from AuthorshipDiff.call
  def initialize(metadata_diff, file_diff: nil, creator_diff: nil)
    metadata_diff.map do |key, value|
      hash[key] = Diffy::Diff.new(*value)
    end
    @files = file_diff || {}
    @creators = creator_diff || {}
  end

  # @return [Array<Symbol>] for each changed metadata term
  def terms
    hash.keys
  end

  # @note this uses the same structure as the MetadataDiff hash, but the value of each changed term is a Diffy::Diff
  def hash
    @hash ||= ActiveSupport::HashWithIndifferentAccess.new
  end

  delegate :[], to: :hash

  # @return [Array<RenamedFile>]
  def renamed_files
    files.fetch(:renamed, []).map do |renamed_files|
      RenamedFile.new(
        title: Diffy::Diff.new(*renamed_files.map(&:title)),
        size: renamed_files.first.size,
        mime_type: renamed_files.first.mime_type
      )
    end
  end

  # @return [Array<FileVersionMembership>]
  def deleted_files
    files.fetch(:deleted, [])
  end

  # @return [Array<FileVersionMembership>]
  def added_files
    files.fetch(:added, [])
  end

  # @return [Array<Diffy::Diff>]
  def renamed_creators
    creators.fetch(:renamed, []).map do |renamed_creators|
      Diffy::Diff.new(*renamed_creators.map(&:display_name))
    end
  end

  # @return [Array<Authorship>]
  def deleted_creators
    creators.fetch(:deleted, [])
  end

  # @return [Array<Authorship>]
  def added_creators
    creators.fetch(:added, [])
  end
end
