# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlashMessageComponent, type: :component do
  let(:result) { render_inline(described_class.new(flash: flash)) }

  describe 'rendering' do
    context 'with a success flash message' do
      let(:flash) { [['success', 'Success flash message']] }

      specify do
        expect(result.css('div.alert-success').text).to match(/Success flash message/)
      end
    end

    context 'with a notice flash message' do
      let(:flash) { [['notice', 'Notice flash message']] }

      specify do
        expect(result.css('div.alert-info').text).to match(/Notice flash message/)
      end
    end

    context 'with an alert flash message' do
      let(:flash) { [['alert', 'Alert flash message']] }

      specify do
        expect(result.css('div.alert-warning').text).to match(/Alert flash message/)
      end
    end

    context 'with an error flash message' do
      let(:flash) { [['error', 'Error flash message']] }

      specify do
        expect(result.css('div.alert-danger').text).to match(/Error flash message/)
      end
    end

    context 'with an unspecified flash message' do
      let(:flash) { [['unspecified flash message', 'Unspecified flash message']] }

      specify do
        expect(result.css('div.alert-unspecified').text).to match(/Unspecified flash message/)
      end
    end

    context 'with multiple messages' do
      let(:flash) do
        [
          ['notice', 'First flash message'],
          ['error', 'Second flash message']
        ]
      end

      specify do
        expect(result.css('div.alert-info').text).to match(/First flash message/)
        expect(result.css('div.alert-danger').text).to match(/Second flash message/)
      end
    end

    context 'when the application is read-only', :read_only do
      let(:flash) { [] }

      specify do
        expect(result.css('div.alert-warning').text).to match(/#{I18n.t('read_only')}/)
      end
    end

    context 'when providing a custom read-only mesage', :read_only do
      let(:flash) { [] }

      before { create(:application_setting) }

      specify do
        expect(result.css('div.alert-warning').text).to match(/#{ApplicationSetting.instance.read_only_message}/)
      end
    end

    context 'with an announcement' do
      let(:flash) { [] }

      before { create(:application_setting) }

      specify do
        expect(result.css('div.alert-info').text).to match(/#{ApplicationSetting.instance.announcement}/)
      end
    end

    context 'without an announcement' do
      let(:flash) { [] }

      before { create(:application_setting, announcement: '') }

      specify do
        expect(result.css('div.alert-info')).to be_empty
      end
    end
  end
end
