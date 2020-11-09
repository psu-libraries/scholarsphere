# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'
require 'seedbank'

unless Rails.env.production?
  Rails.root.join('tasks').children.map { |file| load(file) }
end

Rails.application.load_tasks
Seedbank.load_tasks if defined?(Seedbank)
