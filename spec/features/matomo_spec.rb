# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Matomo Traking Code' do
  before do
    ENV['MATOMO_TEST'] = 'true'
    Capybara.ignore_hidden_elements = false
  end

  after do
    ENV.delete('MATOMO_TEST')
    Capybara.ignore_hidden_elements = true
  end

  it 'has the default configuration' do
    visit(blacklight_path)
    expect(page).to have_content('https://analytics.libraries.psu.edu/matomo')
    expect(page).to have_content('18')
    expect(page).to have_content('/* tracker methods like "setCustomDimension" should be called before "trackPageView" */')
  end
end
