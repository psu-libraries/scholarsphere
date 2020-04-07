# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkHistories::WorkHistoryComponent, type: :component, versioning: true do
  let(:user) { create :user }

  let(:work) { create :work, versions: [draft, v1], depositor: user.actor }

  let(:draft) { build :work_version, :draft, title: 'Draft Version', work: nil, created_at: 1.day.ago }
  let(:v1) { build :work_version, :published, title: 'Published v1', work: nil, created_at: 3.days.ago }

  # This is normally done automatically in the controller, but we need to do it
  # here to get our user on the changes above
  before do
    PaperTrail.request.whodunnit = user.id
  end

  describe 'rendering' do
    it 'renders the work history' do
      result = render_inline(described_class, work: work)

      expect(result.css('h3').text)
        .to include("Version #{draft.version_number}")
        .and include("Version #{v1.version_number}")

      expect(result.css('.work-history__changes').length).to eq 2

      # Draft version has work-version changes but no files
      expect(result.css("#work_version_changes_#{draft.id} .work-history__change--work-version")).to be_present
      expect(result.css("#work_version_changes_#{draft.id} .work-history__change--file")).to be_empty

      # Published version has work-version, file, and creator changes
      expect(result.css("#work_version_changes_#{v1.id} .work-history__change--work-version")).to be_present
      expect(result.css("#work_version_changes_#{v1.id} .work-history__change--file")).to be_present
      expect(result.css("#work_version_changes_#{v1.id} .work-history__change--creator")).to be_present
    end

    context 'when the user cannot be found' do
      it 'renders a null user' do
        work # Implicitly create all user records via the `let`s

        # We can't actually delete a user due to FK constraints, but we can
        # artificially alter one of the PaperTrail::Versions to link to a user
        # that doesn't exist :)
        v1.versions.last.update(whodunnit: '12345')

        result = render_inline(described_class, work: work)
        expect(result.css("#work_version_changes_#{v1.id}").text).to include '[unknown user]'
      end
    end
  end
end
