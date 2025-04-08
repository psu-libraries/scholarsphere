# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationSetting do
  describe 'table' do
    it { is_expected.to have_db_column(:read_only_message).of_type(:string) }
    it { is_expected.to have_db_column(:announcement).of_type(:text) }
  end

  describe '::instance' do
    context 'when settings do not exist' do
      specify do
        expect {
          described_class.instance
        }.to change(described_class, :count).by(1)
      end
    end

    context 'when settins are present' do
      before { create(:application_setting) }

      specify do
        expect {
          described_class.instance
        }.not_to change(described_class, :count)
      end
    end
  end

  describe '::before_save' do
    before { create(:application_setting) }

    it 'prevents another instance from being persisted' do
      expect { described_class.create }.to raise_error(ArgumentError, 'ApplicationSetting is a singleton')
    end
  end
end
