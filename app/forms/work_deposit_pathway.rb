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
    elsif instrument?
      Instrument::DetailsForm.new(resource)
    else
      General::DetailsForm.new(resource)
    end
  end

  def contributors_form
    if work? && !instrument?
      ContributorsFormBase.new(resource)
    elsif work? && instrument?
      Instrument::ContributorsForm.new(resource)
    else
      resource
    end
  end

  def publish_form
    if scholarly_works?
      ScholarlyWorks::PublishForm.new(resource)
    elsif data_and_code?
      DataAndCode::PublishForm.new(resource)
    elsif instrument?
      Instrument::PublishForm.new(resource)
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

  def allows_mint_doi_request?
    (data_and_code? || instrument?) && @resource.doi_blank? && DoiMintingStatus.new(@resource.work).blank?
  end

  def work?
    Work::Types.all.include?(work_type)
  end

  def data_and_code?
    Work::Types.data_and_code.include?(work_type)
  end

  def instrument?
    Work::Types.instrument.include?(work_type)
  end

  private

    attr_reader :resource

    delegate :work_type, to: :resource

    def scholarly_works?
      Work::Types.scholarly_works.include?(work_type)
    end

    class WorkVersionFormBase
      include ActiveModel::Model

      COMMON_FIELDS = %w{
        description
        published_date
        subtitle
        keyword
        publisher
        related_url
        subject
        language
      }.freeze

      def initialize(work_version)
        @work_version = work_version
      end

      def self.model_name
        WorkVersion.model_name
      end

      def valid?
        super
        unless work_version.valid?
          work_version.errors.each do |error|
            unless errors.find { |e| e.attribute == error.attribute && e.message == error.message }
              errors.add(error.attribute, error.message)
            end
          end
          false
        end
        errors.none?
      end

      alias_method :validate, :valid?

      def save(context: nil)
        if valid?
          work_version.save(context: context)
        else
          false
        end
      end

      def show_autocomplete_form?
        false
      end

      def imported_metadata_from_rmd?
        imported_metadata_from_rmd == true
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
               :mint_doi_requested,
               to: :work_version, prefix: false

      private

        attr_reader :work_version
    end

    class DetailsFormBase < WorkVersionFormBase
      validates :description, presence: true

      validates :published_date,
                presence: true,
                edtf_date: true
    end

    class ContributorsFormBase < WorkVersionFormBase
      delegate :creators,
               :creators_attributes=,
               :build_creator,
               :contributor,
               :contributor=,
               to: :work_version, prefix: false

      def form_partial
        'non_instrument_work_version'
      end
    end

    module General
      class DetailsForm < DetailsFormBase
        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(
            %w{
              publisher_statement
              identifier
              based_near
              source
              version_name
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        delegate :form_partial, to: :work_version
      end
    end

    module ScholarlyWorks
      class DetailsForm < DetailsFormBase
        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(
            %w{
              title
              publisher_statement
              identifier
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        def form_partial
          'scholarly_works_work_version'
        end

        def show_autocomplete_form?
          imported_metadata_from_rmd == nil
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
          WorkVersionFormBase::COMMON_FIELDS.union(
            %w{
              based_near
              source
              version_name
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        def form_partial
          'data_and_code_work_version'
        end
      end

      class PublishForm < WorkVersionFormBase
        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(
            %w{
              title
              based_near
              source
              version_name
              rights
              depositor_agreement
              contributor
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        validate :includes_readme_file,
                 if: :published?

        def form_partial
          'data_and_code_work_version'
        end

        delegate :aasm_state=,
                 :aasm_state,
                 :publish,
                 :file_resources,
                 :work_attributes=,
                 :creators_attributes=,
                 :creators,
                 :contributor,
                 :file_version_memberships,
                 :initial_draft?,
                 :aasm,
                 :update_column,
                 :draft_curation_requested=,
                 :mint_doi_requested=,
                 :set_thumbnail_selection,
                 to: :work_version,
                 prefix: false

        private

          def includes_readme_file
            unless file_resources.find do |fr|
              fr.file_data['metadata']['size'].positive? &&
                  fr.file_data['metadata']['filename'] =~ /readme/i
            end && file_resources.find do |fr|
              fr.file_data['metadata']['filename'] !~ /readme/i
            end
              errors.add(:file_resources, :readme)
            end
          end
      end
    end

    module Instrument
      def form_partial
        'instrument_work_version'
      end

      class DetailsForm < DetailsFormBase
        include Instrument

        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(
            %w{
              title
              identifier
              model
              instrument_type
              measured_variable
              available_date
              decommission_date
              related_identifier
              alternative_identifier
              instrument_resource_type
              funding_reference
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end
      end

      class ContributorsForm < WorkVersionFormBase
        include Instrument

        def self.form_fields
          %w{
            owner
            manufacturer
            contributor
          }.freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        validates :owner, :manufacturer, presence: true
      end

      class PublishForm < WorkVersionFormBase
        include Instrument

        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(
            %w{
              title
              owner
              identifier
              manufacturer
              model
              instrument_type
              measured_variable
              available_date
              decommission_date
              related_identifier
              alternative_identifier
              instrument_resource_type
              funding_reference
              rights
              depositor_agreement
              contributor
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        validate :includes_readme_file_and_image,
                 if: :published?

        validates :decommission_date,
                  edtf_date: true

        validates :available_date,
                  edtf_date: true

        validates :owner, :manufacturer, presence: true

        delegate :aasm_state=,
                 :aasm_state,
                 :publish,
                 :file_resources,
                 :work_attributes=,
                 :creators_attributes=,
                 :creators,
                 :contributor,
                 :file_version_memberships,
                 :initial_draft?,
                 :aasm,
                 :update_column,
                 :draft_curation_requested=,
                 :mint_doi_requested=,
                 :set_thumbnail_selection,
                 :set_publisher_as_scholarsphere,
                 to: :work_version,
                 prefix: false

        private

          def includes_readme_file_and_image
            unless file_resources.find do |fr|
              fr.file_data['metadata']['size'].positive? &&
                  fr.file_data['metadata']['filename'] =~ /readme/i
            end && file_resources.find do |fr|
              (fr.file_data['metadata']['filename'] !~ /readme/i &&
              fr.file_data['metadata']['filename'] =~ /png|jpeg|tiff/i)
            end
              errors.add(:file_resources, :readme_and_image)
            end
          end
      end
    end
end
