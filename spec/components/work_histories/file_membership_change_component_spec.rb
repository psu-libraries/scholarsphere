# frozen_string_literal: true

require 'rails_helper'

# @note This spec uses a nonstandard format, where I lumped everything into a
# single it-block. The reason is that this component represents a
# PaperTrail::Version object, and we must therefore use real live PaperTrail to
# test it properly--which is very slow when setting up and tearing down
# factories between every single test run. Instead I've tried to re-use as many
# objects as possible in a single it-block with big comments to denote each test

RSpec.describe WorkHistories::FileMembershipChangeComponent, type: :component do
  let(:user) { build_stubbed :user }

  describe '#initialize' do
    it 'requires paper_trail_version to apply to a FileVersionMembership' do
      expect {
        described_class.new(
          user: user,
          paper_trail_version: instance_spy('PaperTrail::Version', item_type: 'WorkVersion')
        )
      }.to raise_error(ArgumentError)
    end
  end

  describe 'rendering', versioning: true do
    it 'renders the correct state given the paper trail version' do
      ##########################################################################
      #
      # Context: when the FileVersionMembership has been created
      #
      ##########################################################################
      file_version_membership = create :file_version_membership
      paper_trail_version = file_version_membership.versions.last
      allow(paper_trail_version).to receive(:created_at)
        .and_return(Time.zone.parse('2019-12-20 14:00:00'))
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # It: renders the created state with properly formatted times
      #
      expect(result.at('li').attr('id')).to eq "change_#{paper_trail_version.id}"
      expect(result.css('.version-timeline__change--create')).to be_present
      expect(result.css('.version-timeline__change-action').text).to include 'Added'
      expect(result.css('.version-timeline__change-timestamp').text).to eq 'December 20, 2019 14:00'
      expect(result.css('.version-timeline__change-user').text).to eq user.access_id
      expect(result.css('.work-history__files').text).to include file_version_membership.title

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
        .to eq I18n.t!('dashboard.work_history.unknown_user')

      ##########################################################################
      #
      # Context: when the FileVersionMembership has been renamed
      #
      ##########################################################################
      file_version_membership.update!(title: 'old.png')
      file_version_membership.update!(title: 'new.png')
      paper_trail_version = file_version_membership.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # It: shows both old a new filenames
      #
      expect(result.css('.version-timeline__change--rename')).to be_present
      expect(result.css('.version-timeline__change-action').text).to include 'Renamed'
      expect(result.css('.work-history__files').text).to include('old.png').and include('new.png')

      ##########################################################################
      #
      # Context: when the FileVersionMembership has been destroyed
      #
      ##########################################################################
      file_version_membership.update!(title: 'destroy-test.png')
      file_version_membership.destroy
      paper_trail_version = file_version_membership.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # It: shows the delete event
      #
      expect(result.css('.version-timeline__change--delete')).to be_present
      expect(result.css('.version-timeline__change-action').text).to include 'Deleted'
      expect(result.css('.work-history__files').text).to include('destroy-test.png')
    end
  end
end
