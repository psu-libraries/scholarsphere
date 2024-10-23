# frozen_string_literal: true

class AccessibilityCheckResult < ApplicationRecord
  belongs_to :file_resource

  after_commit :broadcast_to_file_version_memberships

  validates :detailed_report, presence: true

  def score
    "#{num_passed} out of #{num_total} passed"
  end

  def failures_present?
    num_passed != num_total
  end

  def readable_report
    format_report
  end

  private

    def num_passed
      detailed_report.values.flatten.count { |rule| rule['Status'] == 'Passed' }
    end

    def num_total
      detailed_report.values.flatten.count
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

  def format_report
    raw_report = detailed_report.values.flatten
    failures = raw_report.select { |rule| rule['Status'] == 'Failed' }
    success = raw_report.select { |rule| rule['Status'] == 'Passed' }
    manual_review = raw_report.select { |rule| rule['Status'] == 'Needs manual check' }

    failures.each do |rule|
      rule['link'] = remediation_link(rule["Rule"])
    end

    formatted_report = { "Success" => success, "Failures" => failures, "Manual Review" => manual_review }
  end

  def remediation_link(rule)
    case rule
    when 'Accessibility permission flag'
        "#{base_url}Perms"
    when 'Image-only PDF'
        "#{base_url}ImageOnlyPDF"
    when 'Tagged PDF'
        "#{base_url}TaggedPDF"
    when 'Logical Reading Order'
        "#{base_url}LogicalRO"
    when 'Primary language'
        "#{base_url}PrimeLang"
    when 'Title'
        "#{base_url}DocTitle"
    when 'Bookmarks'
        "#{base_url}Bookmarks"
    when 'Color contrast'
        "#{base_url}ColorContrast"
    when 'Tagged content'
        "#{base_url}TaggedCont"
    when 'Tagged annotations'
        "#{base_url}TaggedAnnots"
    when 'Tab order'
        "#{base_url}TabOrder"
    when 'Character encoding'
        "#{base_url}CharEnc"
    when 'Tagged multimedia'
        "#{base_url}Multimedia"
    when 'Screen flicker'
        "#{base_url}FlickerRate"
    when 'Scripts'
        "#{base_url}Scripts"
    when 'Timed responses'
        "#{base_url}TimedResponses"
    when 'Navigation links'
        "#{base_url}NavLinks"
    when 'Tagged form fields'
        "#{base_url}TaggedFormFields"
    when 'Field descriptions'
        "#{base_url}FormFieldNames"
    when 'Figures alternate text'
        "#{base_url}FigAltText"
    when 'Nested alternate text'
        "#{base_url}NestedAltText"
    when 'Associated with content'
        "#{base_url}AltTextNoContent"
    when 'Hides annotation'
        "#{base_url}HiddenAnnot"
    when 'Other elements alternate text'
        "#{base_url}OtherAltText"
    when 'Rows'
        "#{base_url}TableRows"
    when 'TH and TD'
        "#{base_url}THTD"
    when 'Headers'
        "#{base_url}TableHeaders"
    when 'Regularity'
        "#{base_url}RegularTable"
    when 'Summary'
        "#{base_url}TableSummary"
    when 'List items'
        "#{base_url}ListItems"
    when 'Lbl and LBody'
        "#{base_url}LblLBody"
    when 'Appropriate nesting'
        "#{base_url}Headings"
    else
      'https://helpx.adobe.com/acrobat/using/create-verify-pdf-accessibility.html'
    end
  end

  def base_url
    'http://www.adobe.com/go/acrobat11_accessibility_checker_en#'
  end
end
