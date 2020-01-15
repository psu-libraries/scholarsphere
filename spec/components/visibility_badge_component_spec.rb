# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VisibilityBadgeComponent, type: :component do
  let(:node) { render_inline(described_class.new(work: work)) }
  let(:image) { node.css('img').first }
  let(:badge) { node.css('span').first }

  context 'when a work is open access' do
    let(:work) { build(:work) }

    specify do
      expect(image.attributes['src'].value).to match(/visibility-open/)
      expect(image.classes).to contain_exactly('visibility')
      expect(badge.text).to include('Open Access')
      expect(badge.classes).to include('badge', 'visibility', 'visibility--open')
    end
  end

  context 'when a work is Penn State only' do
    let(:work) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

    specify do
      expect(image.attributes['src'].value).to match(/visibility-authorized/)
      expect(image.classes).to contain_exactly('visibility')
      expect(badge.text).to include('Penn State')
      expect(badge.classes).to include('badge', 'visibility', 'visibility--authorized')
    end
  end

  context 'when the work is private' do
    let(:work) { build(:work, visibility: Permissions::Visibility::PRIVATE) }

    specify do
      expect(image.attributes['src'].value).to match(/visibility-private/)
      expect(image.classes).to contain_exactly('visibility')
      expect(badge.text).to include('Restricted')
      expect(badge.classes).to include('badge', 'visibility', 'visibility--private')
    end
  end
end
