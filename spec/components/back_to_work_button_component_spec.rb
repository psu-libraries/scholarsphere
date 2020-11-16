# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackToWorkButtonComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(work: work) }
  let(:result) { render_inline(component).css('a').first }

  context 'when the Work has a latest published version' do
    let(:work) { create :work, has_draft: false, versions_count: 1 }

    it "renders a link back to the _Work's_ resource page" do
      expect(result.text).to eq I18n.t('dashboard.works.edit.back', raise: true)
      expect(result[:href]).to eq resource_path(work.uuid)
    end
  end

  context 'when the has only a draft' do
    let(:work) { create :work, has_draft: true, versions_count: 1 }

    it "renders a link back to the _draft Version's_ resource page" do
      expect(result[:href]).to eq resource_path(work.draft_version.uuid)
    end
  end
end
