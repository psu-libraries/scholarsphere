# /Users/ajk5603/projects/scholarsphere/spec/factories/accessibility_check_result.rb

FactoryBot.define do
  factory :accessibility_check_result do
    detailed_report { 
      {
                   'Detailed Report' => {
                     'Alternate Text' => [
                       { 'Description' => 'Figures require alternate text', 'Rule' => 'Figures alternate text',
                         'Status' => 'Failed' },
                       { 'Description' => 'Alternate text that will never be read',
                         'Rule' => 'Nested alternate text', 'Status' => 'Failed' },
                       { 'Description' => 'Alternate text must be associated with some content',
                         'Rule' => 'Associated with content', 'Status' => 'Failed' },
                       { 'Description' => 'Alternate text should not hide annotation',
                         'Rule' => 'Hides annotation', 'Status' => 'Failed' },
                       { 'Description' => 'Other elements that require alternate text',
                         'Rule' => 'Other elements alternate text', 'Status' => 'Failed' }
                     ],
                     'Document' => [
                       { 'Description' => 'Accessibility permission flag must be set',
                         'Rule' => 'Accessibility permission flag', 'Status' => 'Passed' },
                       { 'Description' => 'Document is not image-only PDF', 'Rule' => 'Image-only PDF',
                         'Status' => 'Passed' },
                       { 'Description' => 'Document is tagged PDF', 'Rule' => 'Tagged PDF',
                         'Status' => 'Failed' },
                       { 'Description' => 'Document structure provides a logical reading order', 'Rule' => 'Logical Reading Order',
                         'Status' => 'Needs manual check' },
                       { 'Description' => 'Text language is specified', 'Rule' => 'Primary language',
                         'Status' => 'Failed' },
                       { 'Description' => 'Document title is showing in title bar', 'Rule' => 'Title',
                         'Status' => 'Failed' },
                       { 'Description' => 'Bookmarks are present in large documents', 'Rule' => 'Bookmarks',
                         'Status' => 'Passed' },
                       { 'Description' => 'Document has appropriate color contrast',
                         'Rule' => 'Color contrast', 'Status' => 'Needs manual check' }
                     ],
                     'Forms' => [
                       { 'Description' => 'All form fields are tagged', 'Rule' => 'Tagged form fields',
                         'Status' => 'Passed' },
                       { 'Description' => 'All form fields have description', 'Rule' => 'Field descriptions',
                         'Status' => 'Passed' }
                     ],
                     'Headings' => [
                       { 'Description' => 'Appropriate nesting', 'Rule' => 'Appropriate nesting',
                         'Status' => 'Failed' }
                     ],
                     'Lists' => [
                       { 'Description' => 'LI must be a child of L', 'Rule' => 'List items',
                         'Status' => 'Failed' },
                       { 'Description' => 'Lbl and LBody must be children of LI', 'Rule' => 'Lbl and LBody',
                         'Status' => 'Failed' }
                     ],
                     'Page Content' => [
                       { 'Description' => 'All page content is tagged', 'Rule' => 'Tagged content',
                         'Status' => 'Failed' },
                       { 'Description' => 'All annotations are tagged', 'Rule' => 'Tagged annotations',
                         'Status' => 'Passed' },
                       { 'Description' => 'Tab order is consistent with structure order',
                         'Rule' => 'Tab order', 'Status' => 'Failed' },
                       { 'Description' => 'Reliable character encoding is provided',
                         'Rule' => 'Character encoding', 'Status' => 'Passed' },
                       { 'Description' => 'All multimedia objects are tagged', 'Rule' => 'Tagged multimedia',
                         'Status' => 'Passed' },
                       { 'Description' => 'Page will not cause screen flicker', 'Rule' => 'Screen flicker',
                         'Status' => 'Passed' },
                       { 'Description' => 'No inaccessible scripts', 'Rule' => 'Scripts',
                         'Status' => 'Passed' },
                       { 'Description' => 'Page does not require timed responses', 'Rule' => 'Timed responses',
                         'Status' => 'Passed' },
                       { 'Description' => 'Navigation links are not repetitive', 'Rule' => 'Navigation links',
                         'Status' => 'Passed' }
                     ],
                     'Tables' => [
                       { 'Description' => 'TR must be a child of Table, THead, TBody, or TFoot',
                         'Rule' => 'Rows', 'Status' => 'Failed' },
                       { 'Description' => 'TH and TD must be children of TR', 'Rule' => 'TH and TD',
                         'Status' => 'Failed' },
                       { 'Description' => 'Tables should have headers', 'Rule' => 'Headers',
                         'Status' => 'Failed' },
                       { 'Description' => 'Tables must contain the same number of columns in each row and rows in each column', 'Rule' => 'Regularity',
                         'Status' => 'Failed' },
                       { 'Description' => 'Tables must have a summary', 'Rule' => 'Summary',
                         'Status' => 'Failed' }
                     ]
                   },
                   'Summary' => {
                     'Description' => 'The checker found problems which may prevent the document from being fully accessible.',
                     'Failed' => 18,
                     'Failed manually' => 0,
                     'Needs manual check' => 2,
                     'Passed' => 12,
                     'Passed manually' => 0,
                     'Skipped' => 0
                   }
                 }
      
     }

    trait :with_error do
      detailed_report { { error: 'An error occurred during the accessibility check.' } }
    end
  end
end