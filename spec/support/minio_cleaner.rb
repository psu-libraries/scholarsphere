# frozen_string_literal: true

def reset_minio
  return unless ENV.key?('S3_ENDPOINT') && system('which aws')

  system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 rb s3://#{ENV['AWS_BUCKET']} --force")
  system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 mb s3://#{ENV['AWS_BUCKET']}")
end

RSpec.configure do |config|
  config.before :suite do
    reset_minio
  end
end
