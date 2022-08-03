# frozen_string_literal: true

RSpec.configure do |configure|
  configure.before(:suite) do
    FileUtils.rm_rf Rails.public_path.join('uploads-test')
  end
end
