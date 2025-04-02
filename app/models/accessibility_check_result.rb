# frozen_string_literal: true

class AccessibilityCheckResult < ApplicationRecord
  belongs_to :file_resource

  after_commit :broadcast_to_file_version_memberships
  after_commit :broadcast_publish_status

  validates :detailed_report, presence: true

  def score
    "#{num_passed} out of #{num_total} passed" if detailed_report.key?('Detailed Report')
  end

  def failures_present?
    detailed_report.key?('Detailed Report') ? num_passed != num_total : error.present?
  end

  def error
    detailed_report['error'] if detailed_report.key?('error')
  end

  def formatted_report
    format_report
  end

  private

    def num_passed
      detailed_report['Detailed Report'].values.flatten.count { |rule| rule['Status'] == 'Passed' }
    end

    def num_total
      detailed_report['Detailed Report'].values.flatten.count
    end

    def broadcast_to_file_version_memberships
      file_resource.file_version_memberships.each do |membership|
        FileVersionMembershipChannel.broadcast_to(
          membership,
          mime_type: membership.mime_type,
          accessibility_score_present: membership.accessibility_score_present?,
          report_download_url: membership.accessibility_report_download_url,
          accessibility_score: membership.accessibility_score
        )
      end
    end

    def broadcast_publish_status
      resource = file_resource.work_versions.last

      ActionCable.server.broadcast(
        "publish_status_channel",
        { allow_publish: AllowPublishService.check(resource) }
      )
    end

    def format_report
      raw_report = detailed_report['Detailed Report'].values.flatten
      failures = raw_report.select { |rule| rule['Status'] == 'Failed' }
      success = raw_report.select { |rule| rule['Status'] == 'Passed' }
      manual_review = raw_report.select { |rule| rule['Status'] == 'Needs manual check' }

      failures.each do |rule|
        rule['link'] = remediation_link(rule['Rule'])
      end

      { 'Success' => success, 'Failures' => failures, 'Manual Review' => manual_review }
    end

    def remediation_link(rule)
      links = {
        'Accessibility permission flag' => 'Perms',
        'Image-only PDF' => 'ImageOnlyPDF',
        'Tagged PDF' => 'TaggedPDF',
        'Logical Reading Order' => 'LogicalRO',
        'Primary language' => 'PrimeLang',
        'Title' => 'DocTitle',
        'Bookmarks' => 'Bookmarks',
        'Color contrast' => 'ColorContrast',
        'Tagged content' => 'TaggedCont',
        'Tagged annotations' => 'TaggedAnnots',
        'Tab order' => 'TabOrder',
        'Character encoding' => 'CharEnc',
        'Tagged multimedia' => 'Multimedia',
        'Screen flicker' => 'FlickerRate',
        'Scripts' => 'Scripts',
        'Timed responses' => 'TimedResponses',
        'Navigation links' => 'NavLinks',
        'Tagged form fields' => 'TaggedFormFields',
        'Field descriptions' => 'FormFieldNames',
        'Figures alternate text' => 'FigAltText',
        'Nested alternate text' => 'NestedAltText',
        'Associated with content' => 'AltTextNoContent',
        'Hides annotation' => 'HiddenAnnot',
        'Other elements alternate text' => 'OtherAltText',
        'Rows' => 'TableRows',
        'TH and TD' => 'THTD',
        'Headers' => 'TableHeaders',
        'Regularity' => 'RegularTable',
        'Summary' => 'TableSummary',
        'List items' => 'ListItems',
        'Lbl and LBody' => 'LblLBody',
        'Appropriate nesting' => 'Headings'
      }

      "#{base_url}#{links[rule] || 'https://helpx.adobe.com/acrobat/using/create-verify-pdf-accessibility.html'}"
    end

    def base_url
      'http://www.adobe.com/go/acrobat11_accessibility_checker_en#'
    end
end
