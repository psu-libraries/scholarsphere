# frozen_string_literal: true

class NavbarComponent < ApplicationComponent
  attr_reader :current_user

  def initialize(current_user:)
    @current_user = current_user
  end

  def home?
    current_page?('/')
  end

  def display_name
    "#{current_user.name} (#{current_user.access_id})"
  end
end
