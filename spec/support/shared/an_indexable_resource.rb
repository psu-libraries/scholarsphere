# frozen_string_literal: true

RSpec.shared_examples 'an indexable resource' do
  it { is_expected.to respond_to(:update_index) }
  it { is_expected.to respond_to(:update_index_async) }

  describe 'after destroy' do
    before { allow(SolrDeleteJob).to receive(:perform_later) }

    it 'removes the resource from the index' do
      resource.destroy
      expect(SolrDeleteJob).to have_received(:perform_later).with(resource.uuid)
    end
  end
end
