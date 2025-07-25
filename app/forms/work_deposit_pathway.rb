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
    elsif grad_culminating_experiences?
      GradCulminatingExperiences::DetailsForm.new(resource)
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

  def publish_form(current_user: nil)
    if scholarly_works?
      ScholarlyWorks::PublishForm.new(resource)
    elsif data_and_code?
      DataAndCode::PublishForm.new(resource, current_user:)
    elsif instrument?
      Instrument::PublishForm.new(resource)
    elsif grad_culminating_experiences?
      GradCulminatingExperiences::PublishForm.new(resource)
    else
      resource
    end
  end

  def allows_visibility_change?
    !data_and_code? && !grad_culminating_experiences?
  end

  def allows_curation_request?
    data_and_code? && !@resource.draft_curation_requested && !@resource.accessibility_remediation_requested
  end

  def allows_accessibility_remediation_request?
    work? &&
      !@resource.accessibility_remediation_requested &&
      !@resource.draft_curation_requested &&
      !data_and_code? &&
      !instrument? &&
      @resource.file_version_memberships.any?(&:accessibility_failures?)
  end

  def allows_mint_doi_request?
    (data_and_code? || instrument? || grad_culminating_experiences?) && resource_has_no_doi?
  end

  def has_mint_doi_option?
    (data_and_code? || grad_culminating_experiences?) && resource_has_no_doi?
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

  def grad_culminating_experiences?
    Work::Types.grad_culminating_experiences.include?(work_type)
  end

  def fields_to_reset(original_work_type)
    pathway_fields(original_work_type) - pathway_fields(work_type)
  end

  private

    attr_reader :resource

    delegate :work_type, to: :resource

    def scholarly_works?
      Work::Types.scholarly_works.include?(work_type)
    end

    def pathway_fields(work_type)
      module_mapping = {
        Work::Types.scholarly_works => ScholarlyWorks,
        Work::Types.data_and_code => DataAndCode,
        Work::Types.grad_culminating_experiences => GradCulminatingExperiences,
        Work::Types.instrument => Instrument
      }

      mod = module_mapping.find { |types, _| types.include?(work_type) }&.last

      if mod
        mod::DetailsForm.form_fields.union(mod::PublishForm.form_fields)
      else
        General::DetailsForm.form_fields.union(WorkVersionFormBase::COMMON_PUBLISH_FIELDS)
      end
    end

    def resource_has_no_doi?
      @resource.doi_blank? && DoiMintingStatus.new(@resource.work).blank?
    end

    class WorkVersionFormBase
      include ActiveModel::Model

      COMMON_FIELDS = %w{
        description
        published_date
        keyword
        related_url
        language
      }.freeze

      COMMON_PUBLISH_FIELDS = %w{
        title
        rights
        depositor_agreement
        psu_community_agreement
        accessibility_agreement
        sensitive_info_agreement
        contributor
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
               :accessibility_remediation_requested,
               :file_resources,
               :file_version_memberships,
               :mint_doi_requested,
               :has_image_file_resource?,
               to: :work_version, prefix: false

      private

        attr_reader :work_version
    end

    module WorkVersionDetails
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

      delegate :imported_metadata_from_rmd,
               to: :work_version, prefix: false

      def show_autocomplete_form?
        false
      end

      def imported_metadata_from_rmd?
        imported_metadata_from_rmd == true
      end
    end

    class DetailsFormBase < WorkVersionFormBase
      include WorkVersionDetails

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

      validate :validate_creator_names

      def form_partial
        'non_instrument_work_version'
      end

      private

        def validate_creator_names
          creators.each do |creator|
            next if creator.respond_to?(:marked_for_destruction?) && creator.marked_for_destruction?

            if creator.given_name.blank? || creator.surname.blank?
              errors.add(:creators, I18n.t('dashboard.form.contributors.edit.incomplete_name'))
            end
          end
        end
    end

    class PublishFormBase < WorkVersionFormBase
      include WorkVersionDetails
    end

    module General
      class DetailsForm < DetailsFormBase
        def self.form_fields
          WorkVersionDetails::COMMON_FIELDS.union(
            %w{
              publisher_statement
              identifier
              based_near
              source
              version_name
              subject
              publisher
              subtitle
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
          WorkVersionDetails::COMMON_FIELDS.union(
            %w{
              title
              publisher_statement
              identifier
              subject
              publisher
              subtitle
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
        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(WorkVersionFormBase::COMMON_PUBLISH_FIELDS).union(
            %w{
              subject
              publisher
              subtitle
            }
          ).freeze
        end

        def self.method_missing(method_name, *)
          WorkVersion.public_send(method_name, *)
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
          WorkVersionDetails::COMMON_FIELDS.union(
            %w{
              based_near
              source
              version_name
              subject
              publisher
              subtitle
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

      class PublishForm < PublishFormBase
        def initialize(work_version, current_user:)
          super(work_version)
          @current_user = current_user
        end

        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(WorkVersionFormBase::COMMON_PUBLISH_FIELDS).union(
            %w{
              title
              based_near
              source
              version_name
              subject
              publisher
              subtitle
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        validate :includes_readme_file,
                 if: :should_validate_readme?

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
                 :accessibility_remediation_requested=,
                 :mint_doi_requested,
                 :mint_doi_requested=,
                 :set_thumbnail_selection,
                 to: :work_version,
                 prefix: false

        private

          def should_validate_readme?
            return false if !published?
            return false if @current_user.admin? && changed_to_data_and_code?

            true
          end

          def changed_to_data_and_code?
            work_type_update_trails = @work_version.work
              .paper_trail_versions
              .where("event = 'update' AND object_changes -> 'work_type' IS NOT NULL")
            return false if work_type_update_trails.empty?

            change = work_type_update_trails.last.object_changes['work_type'].second
            Work::Types.data_and_code.include?(change)
          end

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
          WorkVersionDetails::COMMON_FIELDS.union(
            %w{
              title
              subject
              publisher
              subtitle
              model
              instrument_type
              measured_variable
              available_date
              decommission_date
              related_identifier
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

        delegate :creators,
                 to: :work_version, prefix: false

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

        def build_creator(*)
          # No-op: Other contributor forms do build_creators but this one does not
        end

        validates :owner, :manufacturer, presence: true
      end

      class PublishForm < PublishFormBase
        include Instrument

        def self.form_fields
          WorkVersionDetails::COMMON_FIELDS.union(WorkVersionFormBase::COMMON_PUBLISH_FIELDS).union(
            %w{
              title
              subject
              publisher
              subtitle
              owner
              manufacturer
              model
              instrument_type
              measured_variable
              available_date
              decommission_date
              related_identifier
              instrument_resource_type
              funding_reference
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

        def form_partial
          'instrument_work_version'
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
                 :set_thumbnail_selection,
                 :set_publisher_as_scholarsphere,
                 to: :work_version,
                 prefix: false

        def mint_doi_requested
          true
        end

        private

          def includes_readme_file_and_image
            unless file_resources.find do |fr|
              fr.file_data['metadata']['size'].positive? &&
                  fr.file_data['metadata']['filename'] =~ /readme/i
            end && file_resources.find do |fr|
              fr.file_data['metadata']['filename'] !~ /readme/i &&
                  fr.file_data['metadata']['filename'] =~ /png|jpeg|tiff/i
            end
              errors.add(:file_resources, :readme_and_image)
            end
          end
      end
    end

    module GradCulminatingExperiences
      REQUIRE_FIELDS = %w{
        sub_work_type
        program
        degree
      }.freeze

      class DetailsForm < DetailsFormBase
        REQUIRE_FIELDS.each { |f| validates f.to_sym, presence: true }

        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(
            REQUIRE_FIELDS
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        def form_partial
          'grad_culminating_experiences_work_version'
        end
      end

      class PublishForm < WorkVersionFormBase
        REQUIRE_FIELDS.each { |f| validates f.to_sym, presence: true }

        def self.form_fields
          WorkVersionFormBase::COMMON_FIELDS.union(WorkVersionFormBase::COMMON_PUBLISH_FIELDS).union(
            REQUIRE_FIELDS
          ).union(
            %w{
              title
              mint_doi_requested
            }
          ).freeze
        end

        form_fields.each do |attr_name|
          delegate attr_name, to: :work_version, prefix: false
          delegate "#{attr_name}=", to: :work_version, prefix: false
        end

        def form_partial
          'grad_culminating_experiences_work_version'
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
                 :set_thumbnail_selection,
                 to: :work_version,
                 prefix: false
      end
    end
end
