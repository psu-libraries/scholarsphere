# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  def visibility
    self[:visibility_ssi]
  end

  def title
    Array.wrap(self[:title_tesim]).first
  end

  def published_date
    Array.wrap(self[:published_date_tesim]).first
  end

  def display_work_type
    self[:display_work_type_ssi]
  end

  def work_type
    self[:work_type_ss]
  end

  def aasm_state
    Array.wrap(self[:aasm_state_tesim]).first
  end

  def version_number
    self[:version_number_isi].to_s
  end

  def creators
    Array.wrap(self[:creators_tesim])
  end

  def deposited_at
    return if self[:deposited_at_dtsi].nil?

    Time.zone.parse(self[:deposited_at_dtsi])
  end

  def embargoed_until
    Time.zone.parse(fetch(:embargoed_until_dtsi, ''))
  rescue ArgumentError
  end

  def embargoed?
    return false if embargoed_until.nil?

    embargoed_until > Time.zone.now
  end

  def work_id
    self[:work_id_isi].to_i
  end

  def thumbnail_url
    self[:thumbnail_url_ssi]
  end
end
