# frozen_string_literal: true

RSpec::Matchers.define :an_access_control_for do |**args|
  match do |access_control|
    access_control.agent == args[:agent] && access_control.access_level == args[:access_level]
  end

  failure_message do |_access_control|
    "expected an access control with #{args}"
  end

  description do
    "be an access control with #{args}"
  end
end
