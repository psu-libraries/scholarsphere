# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisplayDoiComponent, type: :component do
  subject(:component) { described_class.new(doi: doi) }

  let(:button) { render_inline(component).css('button') }

  context 'when the doi is nil' do
    let(:doi) { nil }

    it { is_expected.not_to be_render }
  end

  context 'with a valid doi' do
    let(:doi) { FactoryBotHelpers.valid_doi }

    its(:css_class) { is_expected.to eq('btn-primary') }

    specify { expect(button.text).to include(doi) }
  end

  context 'with an invalid doi' do
    let(:doi) { FactoryBotHelpers.invalid_doi }

    its(:css_class) { is_expected.to eq('btn-danger') }

    specify { expect(button.text).to include("Invalid DOI: #{doi}") }
  end

  context 'with an unmanaged doi' do
    let(:doi) { FactoryBotHelpers.unmanaged_doi }

    its(:css_class) { is_expected.to eq('btn-warning') }

    specify { expect(button.text).to include("Unmanaged DOI: #{doi}") }
  end
end
