# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  describe ActionDispatch::ExceptionWrapper do
    subject { described_class }

    its(:rescue_responses) { is_expected.to include('Pundit::NotAuthorizedError' => :not_found) }
  end
end
