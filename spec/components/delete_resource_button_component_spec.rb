# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteResourceButtonComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:node) { render_inline(described_class.new(resource: resource, html_class: 'btn my-class')) }
  let(:link) { node.css('a').first }

  context 'when given a collection' do
    let(:resource) { build_stubbed :collection }

    it 'renders a delete button for the collection' do
      text = I18n.t!('dashboard.form.actions.destroy.button')
      subtitle = I18n.t!('dashboard.form.actions.destroy.collection')
      confirm = I18n.t!('dashboard.form.actions.destroy.confirm', type: subtitle)

      expect(link.text.strip).to eq "#{text} #{subtitle}"

      expect(link.attributes['href'].value).to eq dashboard_collection_path(resource)
      expect(link.attributes['data-method'].value).to eq 'delete'
      expect(link.attributes['data-confirm'].value).to eq confirm
      expect(link.attributes['class'].value).to eq 'btn my-class'
    end
  end

  context 'when given a draft version' do
    let(:resource) { build_stubbed :work_version }

    before { allow(resource).to receive(:draft?).and_return(true) }

    it 'renders a delete button for the work version' do
      text = I18n.t!('dashboard.form.actions.destroy.button')
      subtitle = I18n.t!('dashboard.form.actions.destroy.draft')
      confirm = I18n.t!('dashboard.form.actions.destroy.confirm', type: subtitle)

      expect(link.text.strip).to eq "#{text} #{subtitle}"

      expect(link.attributes['href'].value).to eq dashboard_work_version_path(resource)
      expect(link.attributes['data-method'].value).to eq 'delete'
      expect(link.attributes['data-confirm'].value).to eq confirm
    end
  end

  context 'when given a published version' do
    let(:resource) { build_stubbed :work_version }
    let(:instance) do
      described_class.new(resource: resource,
                          html_class: 'btn my-class',
                          hide_if_published: hide_if_published)
    end
    let(:node) { render_inline(instance) }

    before { allow(resource).to receive(:draft?).and_return(false) }

    context 'when hide_if_published is TRUE' do
      let(:hide_if_published) { true }

      it 'is not rendered' do
        expect(instance.render?).to eq false
      end
    end

    context 'when hide_if_published is FALSE' do
      let(:hide_if_published) { false }

      it 'renders a delete button for the work version' do
        text = I18n.t!('dashboard.form.actions.destroy.button')
        subtitle = I18n.t!('dashboard.form.actions.destroy.work_version')
        confirm = I18n.t!('dashboard.form.actions.destroy.confirm', type: subtitle)

        expect(link.text.strip).to eq "#{text} #{subtitle}"

        expect(link.attributes['href'].value).to eq dashboard_work_version_path(resource)
        expect(link.attributes['data-confirm'].value).to eq confirm
      end
    end
  end
end
