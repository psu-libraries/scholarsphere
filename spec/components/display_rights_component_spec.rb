# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisplayRightsComponent, type: :component do
  subject(:component) { described_class.new(id: id) }

  let(:element) { render_inline(component).css('.display-rights') }

  context 'when the id is nil' do
    let(:id) { nil }

    it { is_expected.not_to be_render }
  end

  context 'with a valid id' do
    let(:license) { WorkVersion::Licenses.all.sample }
    let(:id) { license['id'] }

    specify { expect(element.search('a').first.attribute('href').text).to eq(id) }
    specify { expect(element.text).to include(license['label']) }
  end

  context 'with an invalid id' do
    let(:id) { 'bogus' }

    it { is_expected.not_to be_render }
  end
end
