# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'About' do
  it 'renders content from a markdown template' do
    visit(about_path)
    expect(page).to have_content('About')
  end
end
