# frozen_string_literal: true

class Curatorship < ApplicationRecord
  belongs_to :user
  belongs_to :work

  def access_id
    user.access_id
  end
end
