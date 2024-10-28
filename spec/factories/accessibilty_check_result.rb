# frozen_string_literal: true

FactoryBot.define do
  factory :accessibility_check_result do
    association :file_resource
    detailed_report { {
      'Forms' =>
      [{ 'Rule' => 'Tagged form fields', 'Status' => 'Passed', 'Description' => 'All form fields are tagged' }],
      'Tables' =>
    [{ 'Rule' => 'Rows', 'Status' => 'Passed', 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot' }],
      'Document' =>
    [{ 'Rule' => 'Accessibility permission flag', 'Status' => 'Passed', 'Description' => 'Accessibility permission flag must be set' },
     { 'Rule' => 'Image-only PDF', 'Status' => 'Needs manual check', 'Description' => 'Document is not image-only PDF' }]
    } }
  end
end
