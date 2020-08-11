# frozen_string_literal: true

require 'rails_helper'

# @note This spec uses a nonstandard format, where I lumped everything into a
# single it-block. The reason is that this component represents a
# PaperTrail::Version object, and we must therefore use real live PaperTrail to
# test it properly--which is very slow when setting up and tearing down
# factories between every single test run. Instead I've tried to re-use as many
# objects as possible in a single it-block with big comments to denote each test

RSpec.describe WorkHistories::CreatorAliasChangeComponent, type: :component do
  let(:user) { build_stubbed :user }

  describe '#initialize' do
    it 'requires paper_trail_version to apply to a WorkVersionCreation' do
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
      # Context: when the WorkVersionCreation has been created
      #
      ##########################################################################
      creator_alias = create :work_version_creation
      paper_trail_version = creator_alias.versions.last
      allow(paper_trail_version).to receive(:created_at)
        .and_return(Time.zone.parse('2019-12-20 14:00:00'))
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # It: renders the created state with properly formatted times
      #
      expect(result.at('li').attr('id')).to eq "change_#{paper_trail_version.id}"
      expect(result.css('.version-timeline__change--create')).to be_present
      expect(result.css('h5').text).to include('Added').and include(creator_alias.alias)
      expect(result.css('.version-timeline__change-timestamp').text).to eq 'December 20, 2019 14:00'
      expect(result.css('.version-timeline__change-user').text).to eq user.access_id

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
      # Context: when the WorkVersionCreation has been renamed
      #
      ##########################################################################
      creator_alias.update!(alias: 'Old Alias')
      creator_alias.update!(alias: 'New Alias')
      paper_trail_version = creator_alias.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # It: shows both old a new filenames
      #
      expect(result.css('.version-timeline__change--rename')).to be_present
      expect(result.css('h5').text).to include('Renamed').and include('New Alias')

      ##########################################################################
      #
      # Context: when the WorkVersionCreation has been destroyed
      #
      ##########################################################################
      creator_alias.update!(alias: 'Destroy Test')
      creator_alias.destroy
      paper_trail_version = creator_alias.versions.last
      result = render_inline(described_class.new(paper_trail_version: paper_trail_version, user: user))

      #
      # It: shows the delete event
      #
      expect(result.css('.version-timeline__change--delete')).to be_present
      expect(result.css('h5').text).to include('Deleted').and include('Destroy Test')
    end
  end
end
