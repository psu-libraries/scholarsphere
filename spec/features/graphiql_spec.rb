# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphiQL interface', type: :feature do
  it 'renders the graphiql page', :js do
    visit(graphiql_path)
    expect(page).to have_content('Welcome to GraphiQL')
  end
end
