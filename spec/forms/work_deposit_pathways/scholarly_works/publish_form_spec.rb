# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkDepositPathway::ScholarlyWorks::PublishForm, type: :model do
  subject(:form) { described_class.new(wv) }

  let(:wv) { instance_double WorkVersion }

  describe '#form_partial' do
    it 'returns scholarly_works_work_version' do
      expect(form.form_partial).to eq 'scholarly_works_work_version'
    end
  end
end
