require 'rails_helper'

RSpec.describe AllowPublishService, type: :service do
  let(:resource) { instance_double('Resource', work_type: 'article', 
                                               draft_curation_requested: false, 
                                               accessibility_remediation_requested: false, 
                                               file_version_memberships: []) }
  let(:service) { described_class.new(resource) }
  let(:admin_user) { instance_double('User', admin?: true) }
  let(:regular_user) { instance_double('User', admin?: false) }

  describe '#allow?' do
    context 'when the resource is a work' do
      context 'when draft curation is requested' do
        before { allow(resource).to receive(:draft_curation_requested).and_return(true) }

        it 'returns false' do
          expect(service.allow?(current_user: regular_user)).to be false
        end
      end

      context 'when accessibility remediation is requested' do
        before { allow(resource).to receive(:accessibility_remediation_requested).and_return(true) }

        it 'returns false' do
          expect(service.allow?(current_user: regular_user)).to be false
        end
      end

      context 'when file version memberships have pending accessibility scores' do
        let(:file_version_membership) { instance_double('FileVersionMembership', accessibility_score_pending?: true) }

        before { allow(resource).to receive(:file_version_memberships).and_return([file_version_membership]) }

        it 'returns false' do
          expect(service.allow?(current_user: regular_user)).to be false
        end
      end

      context 'when none of the conditions are true' do
        it 'returns true' do
          expect(service.allow?(current_user: regular_user)).to be true
        end
      end

      context 'when the user is an admin' do
        it 'returns true regardless of conditions' do
          allow(resource).to receive(:draft_curation_requested).and_return(true)
          allow(resource).to receive(:accessibility_remediation_requested).and_return(true)
          allow(resource).to receive(:file_version_memberships).and_return([instance_double('FileVersionMembership', accessibility_score_pending?: true)])

          expect(service.allow?(current_user: admin_user)).to be true
        end
      end

      context 'when no current_user is passed' do
        it 'returns false if conditions are not met' do
          allow(resource).to receive(:draft_curation_requested).and_return(true)
          allow(resource).to receive(:accessibility_remediation_requested).and_return(false)
          allow(resource).to receive(:file_version_memberships).and_return([])

          expect(service.allow?).to be false
        end

        it 'returns true if conditions are met' do
          allow(resource).to receive(:draft_curation_requested).and_return(false)
          allow(resource).to receive(:accessibility_remediation_requested).and_return(false)
          allow(resource).to receive(:file_version_memberships).and_return([])

          expect(service.allow?).to be true
        end
      end
    end

    context 'when the resource is not a work' do
      before do
        allow(resource).to receive(:work_type).and_return('collection')
      end

      it 'returns true' do
        expect(service.allow?(current_user: regular_user)).to be true
      end
    end
  end
end