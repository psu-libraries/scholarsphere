# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LinkDisabledByTooltipComponent, type: :component do
  let(:result) { render_inline(described_class.new(enabled: enabled, text: text, path: path, tooltip: tooltip)) }

  let(:text) { 'My Link Text' }
  let(:path) { '/path/for/link' }
  let(:tooltip) { 'The tooltip' }

  let(:default_classes) { %w(btn btn-outline-light btn--squish me-lg-2) }

  context 'when enabled' do
    let(:enabled) { true }
    let(:element) { result.css('a').first }

    it 'renders a link to the work form' do
      expect(element).to be_present
      expect(element[:href]).to eq path
    end

    it 'does not render a tooltip' do
      expect(element['data-toggle']).to be_blank
    end

    it 'renders the text' do
      expect(element.text).to eq text
    end

    it 'renders the default classes' do
      expect(element.classes).to eq default_classes
    end
  end

  context 'when disabled' do
    let(:enabled) { false }
    let(:element) { result.css('span').first }

    it 'renders a span tag' do
      expect(element).to be_present
      expect(element[:href]).to be_blank
    end

    it 'renders a tooltip' do
      expect(element['data-toggle']).to eq 'tooltip'
      expect(element['title']).to eq tooltip
    end

    it 'renders the text' do
      expect(element.text).to eq text
    end

    it 'renders the default classes + disabled ones' do
      expect(element.classes).to contain_exactly(
        *default_classes,
        'disabled'
      )
    end
  end

  context 'when providing your own html classes' do
    subject(:classes) { element.classes }

    let(:result) { render_inline(described_class.new(
                                   enabled: enabled,
                                   text: text,
                                   path: path,
                                   tooltip: tooltip,
                                   class_list: 'my custom classes'
                                 )) }
    let(:element) { result.css('*').first }

    context 'when enabled' do
      let(:enabled) { true }

      it { is_expected.to match_array(%w(my custom classes)) }
    end

    context 'when disabled' do
      let(:enabled) { false }

      it { is_expected.to match_array(%w(my custom classes disabled)) }
    end
  end

  context 'when providing your own http method' do
    let(:result) { render_inline(described_class.new(
                                   enabled: enabled,
                                   text: text,
                                   path: path,
                                   tooltip: tooltip,
                                   method: :post
                                 )) }
    let(:element) { result.css('a').first }
    let(:enabled) { true }

    it "triggers Rails' special behavior for post links" do
      expect(element['data-method']).to eq 'post'
    end
  end
end
