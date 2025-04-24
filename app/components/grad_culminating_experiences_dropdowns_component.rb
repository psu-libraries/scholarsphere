# frozen_string_literal: true

class GradCulminatingExperiencesDropdownsComponent < ApplicationComponent
  attr_reader :form,
              :resource

  def initialize(form:, resource:)
    @form = form
    @resource = resource
  end

  def sub_work_type_dropdown
    if work.professional_doctoral_culminating_experience?
      [
        'Capstone Project',
        'Culminating Research Project',
        'Doctor of Nursing Practice Project',
        'Integrative Doctoral Research Project',
        'Praxis Project',
        'Public Performance'
      ].freeze
    elsif work.masters_culminating_experience?
      [
        'Capstone Course Work Product',
        'Capstone Project',
        'Scholarly Paper/Essay (MA/MS)'
      ].freeze
    end
  end

  def programs_dropdown
    if work.professional_doctoral_culminating_experience?
      qa_labels(:doctoral_programs)
    elsif work.masters_culminating_experience?
      qa_labels(:graduate_programs)
    end
  end

  def degrees_dropdown
    if work.professional_doctoral_culminating_experience?
      qa_labels(:doctoral_degrees)
    elsif work.masters_culminating_experience?
      qa_labels(:masters_degrees)
    end
  end

  private

    def qa_labels(basename)
      Qa::Authorities::Local::FileBasedAuthority.new(basename)
        .all
        .filter_map { |p| p['label'] }
    end

    def work
      resource.work
    end
end
