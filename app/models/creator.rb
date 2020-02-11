# frozen_string_literal: true

class Creator < ApplicationRecord
  has_many :work_version_creations,
           dependent: :restrict_with_exception,
           inverse_of: :creator

  has_many :work_versions,
           through: :work_version_creations,
           inverse_of: :creators

  validates :surname,
            presence: true

  def self.find_or_create_by_user(user)
    find_or_create_by(psu_id: user.access_id) do |new_record|
      new_record.email = user.email
      new_record.given_name = user.given_name
      new_record.surname = user.surname
    end
  end

  def default_alias
    super.presence || "#{given_name} #{surname}"
  end
end
