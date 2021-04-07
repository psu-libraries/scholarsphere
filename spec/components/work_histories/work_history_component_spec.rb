# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkHistories::WorkHistoryComponent, type: :component, versioning: true do
  let(:result) { render_inline(component) }
  let(:component) { described_class.new(work: work) }

  let(:user) { create :user }

  let(:work) { create :work, versions: [draft, v1], depositor: user.actor }

  let(:draft) { build :work_version, :draft, title: 'Draft Version', work: nil, created_at: 1.day.ago }
  let(:v1) { build :work_version, :published, title: 'Published v1', work: nil, created_at: 3.days.ago }

  let(:mock_helpers) { spy 'MockHelpers', policy: mock_policy }
  let(:mock_policy) { instance_spy 'WorkVersionPolicy', navigable?: true }

  before do
    # This is normally done automatically in the controller, but we need to do it
    # here to get our user on the changes above
    PaperTrail.request.whodunnit = editor.to_gid

    # Mock out helpers, which are normally provided to us by the ActionView
    # layer, but are not available here in a unit test
    allow(component).to receive(:helpers).and_return(mock_helpers)
  end

  describe 'rendering' do
    context 'when the changes were performed by a standard user' do
      let(:editor) { create(:user) }

      it 'renders the work history' do
        expect(result.css('h3').text)
          .to include("Version #{draft.version_number}")
          .and include("Version #{v1.version_number}")

        expect(result.css('.version-timeline__list').length).to eq 2

        # Draft version has work-version changes but no files
        expect(result.css("#work_version_changes_#{draft.id} .version-timeline__change--work-version")).to be_present
        expect(result.css("#work_version_changes_#{draft.id} .version-timeline__change--file")).to be_empty

        # Published version has work-version, file, and creator changes
        expect(result.css("#work_version_changes_#{v1.id} .version-timeline__change--work-version")).to be_present
        expect(result.css("#work_version_changes_#{v1.id} .version-timeline__change--file")).to be_present
        expect(result.css("#work_version_changes_#{v1.id} .version-timeline__change--creator")).to be_present

        # User's access is displayed
        expect(result.css("#work_version_changes_#{v1.id}").text).to include editor.access_id
      end
    end

    context 'when the changes were performed by an external application' do
      let(:editor) { create(:external_app) }

      it 'renders the work history using the name of the application' do
        work # Implicitly create all user records via the `let`s

        expect(result.css("#work_version_changes_#{v1.id}").text).to include editor.name
      end
    end

    context 'when the changes were performed by a user that cannot be found' do
      let(:editor) { build(:user, id: '12345') }

      it 'renders a null user' do
        work # Implicitly create all user records via the `let`s

        expect(result.css("#work_version_changes_#{v1.id}").text).to include '[unknown user]'
      end
    end

    context 'when some versions should be hidden via the WorkVersionPolicy' do
      let(:editor) { create(:user) }

      let(:navigable_policy) { instance_spy 'WorkVersionPolicy', navigable?: true }
      let(:not_navigable_policy) { instance_spy 'WorkVersionPolicy', navigable?: false }

      before do
        allow(mock_helpers).to receive(:policy).with(draft)
          .and_return(not_navigable_policy)

        allow(mock_helpers).to receive(:policy).with(v1)
          .and_return(navigable_policy)
      end

      it 'only renders changes for versions that the policy allows' do
        expect(result.css('h3').text)
          .to include("Version #{v1.version_number}")

        expect(result.css('h3').text)
          .not_to include("Version #{draft.version_number}")

        expect(result.css('.version-timeline__list').length).to eq 1

        # Draft version is not shown
        expect(result.css("#work_version_changes_#{draft.id} .version-timeline__change--work-version"))
          .not_to be_present

        # Published version is shown
        expect(result.css("#work_version_changes_#{v1.id} .version-timeline__change--work-version")).to be_present
      end
    end
  end
end
