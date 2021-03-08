# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # Required by Devise when not using database_authenticatable
  describe '#new_session_path' do
    subject { helper.new_session_path }

    it { is_expected.to eq(root_path) }
  end

  # Used in app/views/form_fields/*
  describe '#form_field_id' do
    it 'returns a sanitized dom id for the given form object and attribute' do
      # Simulate a vanilla form
      expect(helper.form_field_id(
               instance_double('ActionView::Helpers::FormBuilder', object_name: 'work_version'),
               :title
             )).to eq 'work_version_title'

      # Simulate a form with nested fields
      expect(helper.form_field_id(
               instance_double('ActionView::Helpers::FormBuilder', object_name: 'work_version[work_attributes]'),
               :type
             )).to eq 'work_version_work_attributes_type'
    end
  end
end
