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

      collection.works = []
      collection.save!

      works.each do |work|
        work.versions.each do |version|
          DestroyWorkVersion.call(version, force: true)
        end
      end

      collection.destroy!
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
