# frozen_string_literal: true

require 'shrine'
require 'shrine/storage/file_system'

Shrine.storages =
  if Rails.env.test?
    {
      cache: Shrine::Storage::FileSystem.new('public', prefix: 'uploads-test/cache'), # temporary
      store: Shrine::Storage::FileSystem.new('public', prefix: 'uploads-test') # permanent
    }
  else
    {
      cache: Shrine::Storage::FileSystem.new('public', prefix: 'uploads/cache'), # temporary
      store: Shrine::Storage::FileSystem.new('public', prefix: 'uploads') # permanent
    }
  end

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
Shrine.plugin :upload_endpoint
