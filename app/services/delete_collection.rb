# frozen_string_literal: true

class DeleteCollection
  attr_reader :uuid

  def self.call(uuid)
    instance = new(uuid)
    instance.delete
    instance
  end

  def initialize(uuid)
    @uuid = uuid
    @successful = false # updated by #delete
  end

  def delete
    return false if collection.nil?

    ActiveRecord::Base.transaction do
      works = collection.works.map(&:itself)

      collection.destroy!

      works.each do |work|
        while work.versions.any?
          DestroyWorkVersion.call(work.versions.last, force: true)
        end
      end
    end

    @successful = true
    true
  end

  def successful?
    @successful
  end

  private

    def collection
      @collection ||= Collection.find_by(uuid: uuid)
    end
end
