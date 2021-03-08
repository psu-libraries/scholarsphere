# frozen_string_literal: true

require 'rails_helper'

# @note This spec uses a nonstandard format, where I lumped everything into a
# single it-block. The reason is that this component represents a
# PaperTrail::Version object, and we must therefore use real live PaperTrail to
# test it properly--which is very slow when setting up and tearing down
# factories between every single test run. Instead I've tried to re-use as many
# objects as possible in a single it-block with big comments to denote each test

RSpec.describe WorkHistories::WorkVersionChangeComponent, type: :component do
  let(:user) { build_stubbed :user }

  describe '#initialize' do
    it 'requires paper_trail_version to apply to a WorkVersion' do
      expect {
        described_class.new(
          user: user,
          paper_trail_version: instance_spy('PaperTrail::Version', item_type: 'FileVersionMembership')
        )
      }.to raise_error(ArgumentError)
    end
  end

  describe 'rendering', versioning: true do
    it 'renders the correct state given the paper trail version' do
      ##########################################################################
      #
      # Context: when the WorkVersion has been created
      #
      ##########################################################################
      work_version = create :work_version
      paper_trail_version = work_version.versions.last
      allow(paper_trail_version).to receive(:created_at)
        .and_return(Time.zone.parse('2019-12-20 14:00:00'))
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # It: renders the created state with properly formatted timestamps
      #
      expect(result.at('li').attr('id')).to eq "change_#{paper_trail_version.id}"
      expect(result.css('.version-timeline__change-action').text).to include 'Created'

      expect(result.css('.version-timeline__change-timestamp').text).to eq 'December 20, 2019 14:00'
      expect(result.css('.version-timeline__change-user').text).to eq user.access_id

      expect(result.css('.version-timeline__diff')).to be_empty

      ##########################################################################
      #
      # Context: when the WorkVersion has been updated
      #
      ##########################################################################
      work_version.update!(title: 'old')
      work_version.update!(title: 'new')
      paper_trail_version = work_version.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # it: renders the updated state with a diff
      #
      expect(result.css('.version-timeline__change-action').text).to include 'Updated'
      expect(result.css('.version-timeline__change-changed-attributes').text)
        .to eq WorkVersion.human_attribute_name(:title)
      expect(result.css('.version-timeline__diff').text).to include('old').and include('new')

      ##########################################################################
      #
      # Context: when many attributes are updated
      #
      ##########################################################################
      work_version.update!(
        title: 'change-many',
        subtitle: 'change-many',
        keyword: %w(one two),
        rights: 'change-many',
        description: 'change-many'
      )
      paper_trail_version = work_version.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # it: renders a truncated list of changed attributes
      #
      # Using regex here because the order of the attributes above doesn't seem
      # to come out the other side with Papertrail and I don't want random fails
      expect(result.css('.version-timeline__change-changed-attributes').text)
        .to match(/Title, \w+, \w+, and 2 more/)

      ##########################################################################
      #
      # Context: when the User is a null-object
      #
      ##########################################################################
      null_user = User.new
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: null_user))

      #
      # It: renders the null-user properly
      #
      expect(result.css('.version-timeline__change-user').text)
        .to eq I18n.t('dashboard.work_history.unknown_user')

      ##########################################################################
      #
      # Context: when the WorkVersion is published
      #
      ##########################################################################
      work_version = create(:work_version, :able_to_be_published)
      work_version.publish
      work_version.save!
      paper_trail_version = work_version.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # it: renders the published state
      #
      expect(result.css('.version-timeline__change-action').text).to include 'Published'

      ##########################################################################
      #
      # Context: when the WorkVersion is withdrawn
      #
      ##########################################################################
      work_version = create(:work_version, :published)
      work_version.withdraw
      work_version.save!
      paper_trail_version = work_version.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # it: renders the withdrawn state
      #
      expect(result.css('.version-timeline__change-action').text).to include 'Withdrawn'
    end
  end
end
