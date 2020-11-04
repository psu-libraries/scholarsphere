# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VisibilityBadgeComponent, type: :component do
  let(:node) { render_inline(described_class.new(work: work)) }
  let(:badge) { node.css('div').first }

  context 'when a work is open access' do
    let(:work) { build(:work) }

    specify do
      expect(badge.text).to include(I18n.t('visibility_badge_component.label.open'))
      expect(badge.attributes['data-before'].value).to eq('lock_open')
      expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-orange')
    end
  end

  context 'when a work is Penn State only' do
    let(:work) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

    specify do
      expect(badge.text).to include(I18n.t('visibility_badge_component.label.authenticated'))
      expect(badge.attributes['data-before'].value).to eq('pets')
      expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-blue')
    end
  end

  context 'when the work is private' do
    let(:work) { build(:work, visibility: Permissions::Visibility::PRIVATE) }

    specify do
      expect(badge.text).to include(I18n.t('visibility_badge_component.label.restricted'))
      expect(badge.attributes['data-before'].value).to eq('lock')
      expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-red')
    end
  end
end
