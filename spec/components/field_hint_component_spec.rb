# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldHintComponent, type: :component do
  subject(:component) { described_class.new(form: form, attribute: :doi) }

  let(:form) { instance_spy 'FormBuilder', object: resource, object_name: 'work_form' }
  let(:resource) { build_stubbed :work }

  context 'when there is an entry in en.yml' do
    let(:translation) { 'The Hint' }

    before do
      allow(I18n).to receive(:exists?).with('helpers.hint.work.doi').and_return(true)
      allow(I18n).to receive(:t).with('helpers.hint.work.doi').and_return(translation)
    end

    its(:render?) { is_expected.to eq true }
    its(:dom_id) { is_expected.to eq 'work_form_doi-hint' }

    it 'renders' do
      expect(
        render_inline(component).css('small#work_form_doi-hint').to_html
      ).to include(
        'The Hint'
      )
    end

    context 'when there is html in the en.yml file' do
      let(:translation) { "The <a href='#'>Hint</a>" }

      it 'renders the html raw without escaping it' do
        expect(
          render_inline(component).css('small').to_html
        ).to include(
          %(The <a href="#">Hint</a>)
        )
      end
    end

    context 'when there is markdown in the en.yml file' do
      let(:translation) { 'The [Hint](#)' }

      it 'renders the markdown into html' do
        expect(
          render_inline(component).css('small').to_html
        ).to include(
          %(The <a href="#">Hint</a>)
        )
      end
    end
  end

  context 'when there is NOT an entry in en.yml' do
    before do
      allow(I18n).to receive(:exists?).with('helpers.hint.work.doi').and_return(false)
    end

    its(:dom_id) { is_expected.to eq nil }
    its(:render?) { is_expected.to eq false }
  end
end
