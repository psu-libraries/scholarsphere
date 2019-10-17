# frozen_string_literal: true

RSpec.configure do |configure|
  configure.before(:suite) do
    FileUtils.rm_rf Rails.root.join('public', 'uploads-test')
  end
end
