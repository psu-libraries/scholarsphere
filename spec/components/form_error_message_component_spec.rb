# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FormErrorMessageComponent, type: :component do
  include ActionView::Helpers::TextHelper

  let(:component) { described_class.new(form: form, heading: heading) }
  let(:result) { render_inline(component) }

  let(:form) { instance_double('ActionView::Helpers::FormBuilder', object: record) }
  let(:record) { build_stubbed(:work_version, title: nil) }
  let(:heading) { 'My Heading' }

  before { record.validate }

  it 'renders a list of errors' do
    expect(result.css('ul li').map(&:text)).to match_array record.errors.full_messages
  end

  context 'when the heading is provided' do
    let(:heading) { 'My Heading' }

    it 'renders the given heading' do
      expect(result.css('.alert-heading').text).to eq heading
    end
  end

  context 'when no heading is provided' do
    let(:heading) { nil }

    it 'renders the default heading' do
      expected_error_msg = I18n.t!(
        'dashboard.form.heading.error_message',
        error: pluralize(record.errors.count, 'error')
      )

      expect(result.css('.alert-heading').text).to eq expected_error_msg
    end
  end
end
