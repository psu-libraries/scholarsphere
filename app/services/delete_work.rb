# frozen_string_literal: true

# @abstract Deletes a work, including all of its versions, without regard to its publication data. Note, this service
# is not intended to be used within the context of the application, but rather as a command-line only method reserved
# for instances when a specific work needs to be deleted.

class DeleteWork
  def self.call(uuid)
    new(uuid: uuid).destroy
  end

  attr_reader :work

  def initialize(uuid:)
    @work = Work.find_by(uuid: uuid)
  end

  def destroy
    work.versions.map do |version|
      version.aasm_state = 'withdrawn'
      version.destroy!
      IndexingService.delete_document(version.uuid)
    end
    work.destroy!
    IndexingService.delete_document(work.uuid, commit: true)
  end
end
