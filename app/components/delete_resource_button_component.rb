# frozen_string_literal: true

class DeleteResourceButtonComponent < ApplicationComponent
  attr_reader :resource, :html_class, :hide_if_published

  def initialize(resource:, html_class:, hide_if_published: false)
    @resource = resource
    @html_class = html_class
    @hide_if_published = hide_if_published
  end

  def render?
    return true if collection?

    resource.draft? || !hide_if_published
  end

  def path
    path_method = if work_version? then :dashboard_work_version_path
                  elsif collection? then :dashboard_collection_path
                  else
                    raise ArgumentError, "#{type} is not supported by this component"
                  end

    method(path_method).call(resource)
  end

  def confirm
    t('confirm', type: button_subtitle)
  end

  def button_text
    t('button')
  end

  def tooltip
    t('tooltip')
  end

  def button_subtitle
    return t('collection') if collection?
    return t('draft') if work_version? && resource.draft?

    t('work_version')
  end

  private

    def type
      resource.class.name
    end

    def collection?
      type == 'Collection'
    end

    def work_version?
      [
        'WorkVersion',
        'WorkDepositPathway::ScholarlyWorks::DetailsForm',
        'WorkDepositPathway::ScholarlyWorks::PublishForm',
        'WorkDepositPathway::General::DetailsForm',
        'WorkDepositPathway::DataAndCode::DetailsForm',
        'WorkDepositPathway::DataAndCode::PublishForm',
        'WorkDepositPathway::Instrument::DetailsForm',
        'WorkDepositPathway::Instrument::PublishForm'
        'WorkDepositPathway::GradCulminatingExperiences::DetailsForm',
        'WorkDepositPathway::GradCulminatingExperiences::PublishForm'
      ].include?(type)
    end

    def t(key, options = {})
      I18n.t!("dashboard.form.actions.destroy.#{key}", **options)
    end
end
