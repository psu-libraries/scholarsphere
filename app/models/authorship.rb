# frozen_string_literal: true

class Authorship < ApplicationRecord
  belongs_to :resource,
             polymorphic: true

  belongs_to :actor,
             inverse_of: :authorships,
             optional: true

  accepts_nested_attributes_for :actor

  after_initialize :set_defaults

  attr_writer :changed_by_system

  has_paper_trail(
    meta: {
      # Explicitly store the resource type and id in the PaperTrail::Version to allow
      # easy access in the work history
      resource_id: :resource_id,
      resource_type: :resource_type,
      changed_by_system: :changed_by_system
    },
    skip: [:instance_token]
  )

  # Fields that contain single values automatically remove blank values
  %i[
    surname
    given_name
    email
  ].each do |field|
    define_method "#{field}=" do |val|
      super(val.presence)
    end
  end

  def psu_id
    actor.try(:psu_id)
  end

  def orcid
    actor.try(:orcid)
  end

  # Force changed_by_system to a boolean
  def changed_by_system
    !!@changed_by_system
  end

  private

    def set_defaults
      self.instance_token ||= SecureRandom.uuid
      return if actor.nil?

      self.given_name ||= actor.given_name
      self.surname ||= actor.surname
      self.email ||= actor.email
      self.display_name ||= "#{self.given_name} #{self.surname}"
    end
end
