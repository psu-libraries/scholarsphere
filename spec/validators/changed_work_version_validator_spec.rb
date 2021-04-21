# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChangedWorkVersionValidator, type: :validator do
  let(:work) { create(:work, has_draft: false) }
  let(:old_version) { work.versions[0] }
  let(:new_version) { BuildNewWorkVersion.call(work.versions[0]) }
  let(:validator) { described_class.new }

  context 'when the versions are identical' do
    before do
      new_version.save
      new_version.reload
      validator.validate(new_version)
    end

    specify do
      expect(new_version.errors.full_messages).to include('Work version is the same as the previous version')
    end
  end

  context 'when the versions have the same files and different metadata' do
    before do
      new_version.save
      new_version.reload
      new_version.title = FactoryBotHelpers.work_title
      validator.validate(new_version)
    end

    specify do
      expect(old_version.title).not_to eq(new_version.title)
      expect(old_version.file_resources).to eq(new_version.file_resources)
      expect(new_version.errors).to be_empty
    end
  end

  context 'when the versions have different files and the same metadata' do
    before do
      new_version.save
      new_version.reload
      new_version.file_resources = build_list(:file_resource, 1)
      validator.validate(new_version)
    end

    specify do
      expect(old_version.title).to eq(new_version.title)
      expect(old_version.file_resources).not_to eq(new_version.file_resources)
      expect(new_version.errors).to be_empty
    end
  end

  context 'when changing the authorship' do
    before do
      new_version.save
      new_version.reload
      new_version.creators.first.update(display_name: Faker::Name.name)
      validator.validate(new_version)
    end

    specify do
      expect(old_version.creators.first.display_name).not_to eq(new_version.creators.first.display_name)
      expect(new_version.errors).to be_empty
    end
  end
end
