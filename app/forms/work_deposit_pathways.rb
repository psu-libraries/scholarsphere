# frozen_string_literal: true

module WorkDepositPathways
  def self.details_form_for(resource)
    case resource.deposit_pathway
    when :scholarly_works
      ScholarlyWorks::DetailsForm.new(resource)
    when :general
      General::DetailsForm.new(resource)
    else
      resource
    end
  end

  class DetailsFormBase
    include ActiveModel::Model
    include ActiveModel::Attributes

    COMMON_FIELDS = %w{
      description
      published_date
      subtitle
      publisher_statement
      keyword
      publisher
      identifier
      related_url
      subject
      language
    }.freeze

    def initialize(work_version)
      @work_version = work_version
      super(work_version.attributes.slice(*self.class.form_fields))
    end

    validates :description, presence: true

    validates :published_date,
              presence: true,
              edtf_date: true

    def self.model_name
      WorkVersion.model_name
    end

    def save(context:)
      if valid?
        work_version.attributes = attributes
        work_version.save(context: context)
      end
    end

    delegate :id,
             :to_param,
             :persisted?,
             :uuid,
             :new_record?,
             :published?,
             :draft?,
             :work,
             :indexing_source=,
             :update_doi=,
             to: :work_version, prefix: false

    private

      attr_reader :work_version
  end

  module General
    class DetailsForm < DetailsFormBase
      def self.form_fields
        DetailsFormBase::COMMON_FIELDS.union(
          %w{
            based_near
            source
            version_name
          }
        ).freeze
      end

      form_fields.each { |attr_name| attribute attr_name }

      validates :version_name,
                allow_blank: true,
                format: {
                  with: /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/, # rubocop:disable Layout/LineLength
                  message: I18n.t('activerecord.errors.work_version.attributes.version_name.format'),
                  multiline: true
                }

      delegate :form_partial, to: :work_version
    end
  end

  module ScholarlyWorks
    class DetailsForm < DetailsFormBase
      def self.form_fields
        DetailsFormBase::COMMON_FIELDS
      end

      form_fields.each { |attr_name| attribute attr_name }

      def form_partial
        'scholarly_works_work_version'
      end
    end
  end
end
