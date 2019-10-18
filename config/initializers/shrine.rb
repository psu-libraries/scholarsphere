# frozen_string_literal: true

require 'shrine'
require 'shrine/storage/s3'
require 'uppy/s3_multipart'

Shrine.storages = Scholarsphere::ShrineConfig.storages

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data
Shrine.plugin :uppy_s3_multipart
