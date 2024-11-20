# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MintableDoiComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(resource: resource) }

  let(:resource) { instance_double('Work', doi: doi, uuid: 'abc-123') }
  let(:html) { render_inline(component) }

  let(:mock_helpers) { double 'MockHelpers', policy: mock_policy, protect_against_forgery?: false }
  let(:mock_policy) { double 'MockPolicy', edit?: false }

  before do
    allow(component).to receive(:helpers).and_return(mock_helpers)
  end

  context 'when the resource already has a doi' do
    let(:doi) { FactoryBotHelpers.valid_doi }

    it 'renders a MintingStatusDoiComponent for the doi' do
      expect(html.text).to include(doi)
    end
  end

  context 'when the user has permissions to create a doi' do
    let(:doi) { nil }

    before { allow(mock_policy).to receive(:edit?).and_return(true) }

    it 'renders a button to allow DOI creation' do
      expect(html.css('form').attribute('action').value)
        .to eq resource_doi_path(resource.uuid)

      expect(html.at_css('button').text).to eq I18n.t!('resources.doi.create')
    end
  end

  context 'when the user does not have permissinos to create the doi' do
    let(:doi) { nil }

    before { allow(mock_policy).to receive(:edit?).and_return(false) }

    it 'does not render' do
      expect(component.render?).to eq false
    end
  end
end
