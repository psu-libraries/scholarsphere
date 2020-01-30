# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PermissionsBuilder do
  subject { Pole.new }

  before(:all) do
    class Dog; end
    class Cat; end

    class Pole
      include PermissionsBuilder.new(level: 'scratch', agents: [Dog, Cat])
    end
  end

  after(:all) do
    ActiveSupport::Dependencies.remove_constant('Dog')
    ActiveSupport::Dependencies.remove_constant('Cat')
    ActiveSupport::Dependencies.remove_constant('Pole')
  end

  it { is_expected.to respond_to(:grant_scratch_access) }
  it { is_expected.to respond_to(:revoke_scratch_access) }
  it { is_expected.to respond_to(:scratch_access?) }
  it { is_expected.to respond_to(:scratch_agents) }
  it { is_expected.to respond_to(:scratch_dogs) }
  it { is_expected.to respond_to(:scratch_dogs=) }
  it { is_expected.to respond_to(:scratch_cats) }
  it { is_expected.to respond_to(:scratch_cats=) }
end
