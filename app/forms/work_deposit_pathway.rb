# frozen_string_literal: true

class WorkDepositPathway
  def initialize(resource)
    @resource = resource
  end

  def details_form
    if scholarly_works?
      ScholarlyWorks::DetailsForm.new(resource)
    elsif data_and_code?
      DataAndCode::DetailsForm.new(resource)
    else
      General::DetailsForm.new(resource)
    end
  end

  def publish_form
    if scholarly_works?
      ScholarlyWorks::PublishForm.new(resource)
    elsif data_and_code?
      DataAndCode::PublishForm.new(resource)
    else
      resource
    end
  end

  def allows_visibility_change?
    !data_and_code?
  end

  def allows_curation_request?
    data_and_code? && !@resource.draft_curation_requested
  end

  def work?
    Work::Types.all.include?(work_type)
  end

  def data_and_code?
    Work::Types.data_and_code.include?(work_type)
  end

  def imported_metadata_from_rmd?
    imported_metadata_from_rmd != true
  end

  private

    attr_reader :resource

    delegate :work_type, to: :resource

    def scholarly_works?
      Work::Types.scholarly_works.include?(work_type)
    end

    class DetailsFormBase
      include ActiveModel::Model
      include ActiveModel::Attributes

      COMMON_FIELDS = %w{
        description
        published_date
        subtitle
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
        work_version.attributes = attributes

        if work_version.valid?
          if valid?
            work_version.attributes = attributes
            work_version.save(context: context)
          end
        else
          validate
          work_version.errors.each do |attr, message|
            errors.add(attr, message)
          end
          false
        end
      end

      def show_autocomplete_form?
        false
      end

      delegate :id,
               :to_param,
               :persisted?,
               :uuid,
               :new_record?,
               :published?,
               :draft?,
               :work,
               :imported_metadata_from_rmd,
               :indexing_source=,
               :update_doi=,
               :work_type,
               :draft_curation_requested,
               to: :work_version, prefix: false

      private

        attr_reader :work_version
    end

    module General
      class DetailsForm < DetailsFormBase
        def self.form_fields
          DetailsFormBase::COMMON_FIELDS.union(
            %w{
              publisher_statement
              based_near
              source
              version_name
            }
          ).freeze
        end

        form_fields.each { |attr_name| attribute attr_name }

        delegate :form_partial, to: :work_version
      end
    end

    module ScholarlyWorks
      class DetailsForm < DetailsFormBase
        def self.form_fields
          DetailsFormBase::COMMON_FIELDS.union(
            %w{
              publisher_statement
            }
          ).freeze
        end

        form_fields.each { |attr_name| attribute attr_name }

        def form_partial
          'scholarly_works_work_version'
        end

        def show_autocomplete_form?
          imported_metadata_from_rmd != true
        end
      end

      class PublishForm < SimpleDelegator
        def self.method_missing(method_name, *args)
          WorkVersion.public_send(method_name, *args)
        end

        def self.respond_to_missing?(method_name, *)
          WorkVersion.respond_to?(method_name)
        end

        def form_partial
          'scholarly_works_work_version'
        end
      end
    end

    module DataAndCode
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

        def form_partial
          'data_and_code_work_version'
        end
      end

      class PublishForm < SimpleDelegator
        def self.method_missing(method_name, *args)
          WorkVersion.public_send(method_name, *args)
        end

        def self.respond_to_missing?(method_name, *)
          WorkVersion.respond_to?(method_name)
        end

        def form_partial
          'data_and_code_work_version'
        end
      end
    end
end
