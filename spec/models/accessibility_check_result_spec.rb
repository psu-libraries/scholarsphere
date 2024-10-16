# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessibilityCheckResult, type: :model do
  let(:accessibility_check_result) { described_class.new(detailed_report: detailed_report, file_resource_id: create(:file_resource, :pdf).id) }

  describe 'table' do
    it { is_expected.to have_db_column(:detailed_report).of_type(:jsonb) }
    it { is_expected.to have_db_index(:file_resource_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:file_resource) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:detailed_report) }
  end

  describe '#score' do
    let(:detailed_report) {
        {
          'Forms' =>
          [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
          'Lists' =>
        [{ 'Rule' => 'List items', 'Status' => 'Failed', 'Description' => 'LI must be a child of L' }],
          'Tables' =>
        [{ 'Rule' => 'Rows', 'Status' => 'Failed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
          'Document' =>
        [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Passed', 'Description' => 'Accessibility permission flag must be set' },
         { 'Rule' => 'Image-only PDF', 'Status' => 'Needs manual check', 'Description' => 'Document is not image-only PDF' }]
        } }

    it 'returns the number of tests with Passed status out of total tests' do
      expect(accessibility_check_result.score).to eq '2 out of 5 passed'
    end
  end

  describe '#failures_present?' do
    context 'when all tests pass' do
      let(:detailed_report) {
          {
            'Forms' =>
            [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
            'Tables' =>
          [{ 'Rule' => 'Rows', 'Status' => 'Passed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
            'Document' =>
          [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Passed', 'Description' => 'Accessibility permission flag must be set' },
           { 'Rule' => 'Image-only PDF', 'Status' => 'Passed', 'Description' => 'Document is not image-only PDF' }]
          } }

      it 'returns false' do
        expect(accessibility_check_result.failures_present?).to be false
      end
    end

    context 'when at least one test fails' do
      let(:detailed_report) {
          {
            'Forms' =>
            [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
            'Tables' =>
          [{ 'Rule' => 'Rows', 'Status' => 'Failed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
            'Document' =>
          [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Passed', 'Description' => 'Accessibility permission flag must be set' },
           { 'Rule' => 'Image-only PDF', 'Status' => 'Passed', 'Description' => 'Document is not image-only PDF' }]
          } }

      it 'returns true' do
        expect(accessibility_check_result.failures_present?).to be true
      end
    end

    context 'when at least one test needs manual review' do
      let(:detailed_report) {
          {
            'Forms' =>
            [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
            'Tables' =>
          [{ 'Rule' => 'Rows', 'Status' => 'Passed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
            'Document' =>
          [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Passed', 'Description' => 'Accessibility permission flag must be set' },
           { 'Rule' => 'Image-only PDF', 'Status' => 'Needs manual check', 'Description' => 'Document is not image-only PDF' }]
          } }

      it 'returns true' do
        expect(accessibility_check_result.failures_present?).to be true
      end
    end
  end
end
