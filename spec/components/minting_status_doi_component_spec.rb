# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MintingStatusDoiComponent, type: :component do
  subject(:component) { described_class.new(resource: resource) }

  let(:resource) { instance_double('Work', doi: doi) }
  let(:mock_minting_status) { instance_double('DoiMintingStatus', present?: false) }

  let(:html) { render_inline(component) }

  before do
    allow(DoiMintingStatus).to receive(:new).with(resource).and_return(mock_minting_status)
    allow(resource).to receive(:validate).and_return(true)
  end

  context 'when the doi is nil' do
    let(:doi) { nil }

    context 'when the minting status is also nil' do
      before { allow(mock_minting_status).to receive(:present?).and_return(false) }

      it { is_expected.not_to be_render }
    end

    context 'when the minting status is present' do
      before { allow(mock_minting_status).to receive(:present?).and_return(true) }

      it { is_expected.to be_render }
    end

    context 'when the resource is invalid' do
      before { allow(resource).to receive(:validate).and_return(false) }

      it { is_expected.to be_render }
      its(:css_class) { is_expected.to eq('text-danger') }
      specify { expect(html.text).to include(I18n.t('resources.doi.blocked')) }
    end
  end

  context 'when a doi is present on the resource' do
    let(:doi) { FactoryBotHelpers.valid_doi }

    before { allow(mock_minting_status).to receive(:present?).and_return(false) }

    it 'renders a DisplayDoiComponent for the doi' do
      expect(html.text).to include(doi)
    end
  end

  context 'with a doi in the process of minting' do
    let(:doi) { nil }

    before do
      allow(mock_minting_status).to receive(:present?).and_return(true)
    end

    context 'when the doi minter is waiting' do
      before do
        allow(mock_minting_status).to receive(:waiting?).and_return(true)
        allow(mock_minting_status).to receive(:minting?).and_return(false)
        allow(mock_minting_status).to receive(:error?).and_return(false)
      end

      its(:css_class) { is_expected.to eq('badge badge-light') }
      specify { expect(html.text).to include(I18n.t('resources.doi.waiting')) }
    end

    context 'when the doi minter is minting' do
      before do
        allow(mock_minting_status).to receive(:waiting?).and_return(false)
        allow(mock_minting_status).to receive(:minting?).and_return(true)
        allow(mock_minting_status).to receive(:error?).and_return(false)
      end

      its(:css_class) { is_expected.to eq('badge badge-light') }
      specify { expect(html.text).to include(I18n.t('resources.doi.minting')) }
    end

    context 'when the doi minter is error' do
      before do
        allow(mock_minting_status).to receive(:waiting?).and_return(false)
        allow(mock_minting_status).to receive(:minting?).and_return(false)
        allow(mock_minting_status).to receive(:error?).and_return(true)
      end

      its(:css_class) { is_expected.to eq('text-danger') }
      specify { expect(html.text).to include(I18n.t('resources.doi.error')) }
    end
  end
end
