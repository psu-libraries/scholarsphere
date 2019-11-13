# frozen_string_literal: true

RSpec.shared_examples 'an authorized dashboard controller' do
  before do
    raise 'perform_request must be set with `let(:perform_request)`' unless defined? perform_request
  end

  context "when signed in, but requesting someone else's resource" do
    before { sign_in create :user }

    it do
      expect {
        perform_request
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when not signed in' do
    subject { response }

    let(:user) { nil }

    before { perform_request }

    it { is_expected.to redirect_to new_user_session_path }
  end
end
