# frozen_string_literal: true

class Actor < ApplicationRecord
  has_one :user,
          required: false,
          dependent: :restrict_with_exception

  has_many :deposited_works,
           class_name: 'Work',
           foreign_key: 'depositor_id',
           inverse_of: 'depositor',
           dependent: :restrict_with_exception

  has_many :proxy_deposited_works,
           class_name: 'Work',
           foreign_key: 'proxy_id',
           inverse_of: 'proxy_depositor',
           dependent: :restrict_with_exception

  has_many :work_version_creations,
           dependent: :restrict_with_exception,
           inverse_of: :actor

  has_many :work_versions,
           through: :work_version_creations,
           inverse_of: :actors

  has_many :collection_creations,
           dependent: :restrict_with_exception,
           inverse_of: :actor

  has_many :collections,
           through: :collection_creations,
           inverse_of: :actors

  validates :surname,
            presence: true

  def default_alias
    super.presence || "#{given_name} #{surname}"
  end
end
