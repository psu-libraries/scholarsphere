# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllowPublishService, type: :service do
  let(:resource) { instance_double('Resource', work_type: 'article', draft_curation_requested: false, accessibility_remediation_requested: false) }
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

      context 'when neither request is pending' do
        it 'returns true' do
          expect(service.allow?(current_user: regular_user)).to be true
        end
      end

      context 'when the user is an admin' do
        it 'returns true regardless of requests' do
          allow(resource).to receive_messages(draft_curation_requested: true, accessibility_remediation_requested: true)

          expect(service.allow?(current_user: admin_user)).to be true
        end
      end

      context 'when no current_user is passed' do
        it 'returns false when a request is pending' do
          allow(resource).to receive(:draft_curation_requested).and_return(true)

          expect(service.allow?).to be false
        end

        it 'returns true when neither request is pending' do
          expect(service.allow?).to be true
        end
      end
    end

    context 'when the resource is not a work' do
      before { allow(resource).to receive(:work_type).and_return('collection') }

      it 'returns true' do
        expect(service.allow?(current_user: regular_user)).to be true
      end
    end
  end
end
