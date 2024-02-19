# frozen_string_literal: true

class WorkDepositPathway
  def initialize(resource)
    @resource = resource
  end

  def details_form
    if scholarly_works?
      ScholarlyWorks::DetailsForm.new(resource)
    elsif general?
      General::DetailsForm.new(resource)
    else
      resource
    end
  end

  def publish_form
    if scholarly_works?
      ScholarlyWorks::PublishForm.new(resource)
    else
      resource
    end
  end

  private

    attr_reader :resource

    delegate :work_type, to: :resource

    # It will probably make sense to promote these predicate methods to the
    # public interface at some point.
    def scholarly_works?
      Work::Types.scholarly_works.include?(work_type)
    end

    def general?
      Work::Types.general.include?(work_type)
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
end
