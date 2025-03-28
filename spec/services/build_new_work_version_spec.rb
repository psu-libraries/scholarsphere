# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildNewWorkVersion, type: :model do
  let!(:work) { create(:work, versions: [initial_work_version]) }
  let(:initial_work_version) do
    build(:work_version,
          :published,
          work: nil, # FactoryBot trick needed for above
          title: 'My Happy Version',
          version_number: 4,
          file_count: 1,
          creator_count: 1)
  end

  let(:initial_file_membership) { initial_work_version.file_version_memberships.first }
  let(:file_resource) { initial_file_membership.file_resource }

  let(:initial_creation) { initial_work_version.creators.first }
  let(:creator) { initial_creation.actor }

  before do
    initial_file_membership.update!(title: 'overridden-title.png')
    initial_creation.update!(display_name: 'My Creator Name', position: 100)
  end

  describe '.call' do
    subject(:new_version) { described_class.call(initial_work_version) }

    it { is_expected.to be_a WorkVersion }
    it { is_expected.not_to be_persisted }
    its(:aasm_state) { is_expected.to eq 'draft' }
    its(:title) { is_expected.to eq 'My Happy Version' }
    its(:work) { is_expected.to eq work }
    its(:version_number) { is_expected.to eq 5 }

    it 'retains the same file resources' do
      expect(new_version.file_version_memberships.length).to eq 1

      new_version.file_version_memberships.first.tap do |membership|
        expect(membership.title).to eq 'overridden-title.png'
        expect(membership.file_resource).to eq file_resource
      end
    end

    it 'retains the same creators' do
      expect(new_version.creators.length).to eq 1

      new_version.creators.first.tap do |creation|
        expect(creation.display_name).to eq 'My Creator Name'
        expect(creation.actor).to eq creator
        expect(creation.position).to eq 100
        expect(creation.instance_token).to eq initial_creation.instance_token
      end
    end

    it "doesn't copy over the ExternalApp, if present" do
      initial_work_version.external_app = build(:external_app)
      expect(new_version.external_app).to be_nil
    end

    it "doesn't change the database" do
      expect { new_version }.not_to change(WorkVersion, :count)
      expect { new_version }.not_to change(FileResource, :count)
    end

    context 'when persisting the new version' do
      it 'returns a WorkVersion that persists as expected' do
        expect {
          new_version.save!
        }.to change(WorkVersion, :count).by(1)
          .and change(FileVersionMembership, :count).by(1)
          .and change(FileResource, :count).by(0)

        new_version.reload
        expect(new_version.file_resources).to contain_exactly(file_resource)
      end
    end
  end
end
