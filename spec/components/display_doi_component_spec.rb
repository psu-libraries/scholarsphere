# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisplayDoiComponent, type: :component do
  subject(:component) { described_class.new(doi: doi) }

  let(:element) { render_inline(component).css('.doi') }

  context 'when the doi is nil' do
    let(:doi) { nil }

    it { is_expected.not_to be_render }
  end

  context 'with a valid doi' do
    let(:doi) { FactoryBotHelpers.valid_doi }

    its(:css_class) { is_expected.to eq('text-primary') }
    its(:tooltip) { is_expected.to eq(I18n.t!('resources.doi.valid')) }

    specify { expect(element.text).to include(doi) }
  end

  context 'with an invalid doi' do
    let(:doi) { FactoryBotHelpers.invalid_doi }

    its(:css_class) { is_expected.to eq('text-danger') }
    its(:tooltip) { is_expected.to eq(I18n.t!('resources.doi.invalid')) }

    specify { expect(element.text).to include(doi) }
  end

  context 'with an unmanaged doi' do
    let(:doi) { FactoryBotHelpers.unmanaged_doi }

    its(:css_class) { is_expected.to eq('text-secondary') }
    its(:tooltip) { is_expected.to eq(I18n.t!('resources.doi.unmanaged')) }

    specify { expect(element.text).to include(doi) }
  end
end
