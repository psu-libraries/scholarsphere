# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VisibilityBadgeComponent, type: :component do
  let(:node) { render_inline(described_class.new(work: work)) }
  let(:badge) { node.css('div').first }
  let(:embargo_date) { 6.days.from_now }

  context 'when a work is open access' do
    let(:work) { build(:work) }

    specify do
      expect(badge.text).to include(I18n.t!('visibility_badge_component.label.open'))
      expect(badge.attributes['data-before'].value).to eq('lock_open')
      expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-orange')
      expect(badge['title']).to be_nil
    end

    context 'when a work is embargoed' do
      let(:work) { build(:work, embargoed_until: embargo_date) }

      specify do
        expect(badge.text).to include(I18n.t!('visibility_badge_component.label.embargoed'))
        expect(badge.attributes['data-before'].value).to eq('lock_clock')
        expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-red')
        expect(badge['title']).to eq(I18n.t!('visibility_badge_component.tooltip.embargoed',
                                             date: embargo_date.strftime('%Y-%m-%d')))
      end
    end
  end

  context 'when a work is Penn State only' do
    let(:work) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

    specify do
      expect(badge.text).to include(I18n.t!('visibility_badge_component.label.authenticated'))
      expect(badge.attributes['data-before'].value).to eq('pets')
      expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-blue')
      expect(badge['title']).to be_nil
    end

    context 'when a work is embargoed' do
      let(:work) { build(:work, embargoed_until: embargo_date, visibility: Permissions::Visibility::AUTHORIZED) }

      specify do
        expect(badge.text).to include(I18n.t!('visibility_badge_component.label.embargoed'))
        expect(badge.attributes['data-before'].value).to eq('lock_clock')
        expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-red')
        expect(badge['title']).to eq(I18n.t!('visibility_badge_component.tooltip.embargoed',
                                             date: embargo_date.strftime('%Y-%m-%d')))
      end
    end
  end

  context 'when the work is private' do
    let(:work) { build(:work, visibility: Permissions::Visibility::PRIVATE) }

    specify do
      expect(badge.text).to include(I18n.t!('visibility_badge_component.label.restricted'))
      expect(badge.attributes['data-before'].value).to eq('lock')
      expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-red')
      expect(badge['title']).to be_nil
    end

    context 'when a work is embargoed' do
      let(:work) { build(:work, embargoed_until: embargo_date, visibility: Permissions::Visibility::PRIVATE) }

      specify do
        expect(badge.text).to include(I18n.t!('visibility_badge_component.label.embargoed'))
        expect(badge.attributes['data-before'].value).to eq('lock_clock')
        expect(badge.classes).to contain_exactly('badge', 'badge--icon', 'badge--icon-red')
        expect(badge['title']).to eq(I18n.t!('visibility_badge_component.tooltip.embargoed',
                                             date: embargo_date.strftime('%Y-%m-%d')))
      end
    end
  end
end
