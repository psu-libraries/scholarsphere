# frozen_string_literal: true

class GradCulminatingExperiencesDropdownsComponent < ApplicationComponent
  attr_reader :form,
              :resource

  def initialize(form:, resource:)
    @form = form
    @resource = resource
  end

  def sub_work_type_dropdown
    if resource.work_type == Work::Types.grad_culminating_experiences.first
      [
        'Capstone Project',
        'Culminating Research Project',
        'Doctor of Nursing Practice Project',
        'Integrative Doctoral Research Project',
        'Praxis Project',
        'Public Performance'
      ].freeze
    elsif resource.work_type == Work::Types.grad_culminating_experiences.second
      [
        'Capstone Course Work Product',
        'Capstone Project',
        'Scholarly Paper/Essay (MA/MS)'
      ].freeze
    end
  end

  def programs_dropdown
    Qa::Authorities::Local::FileBasedAuthority.new(:graduate_programs)
      .all
      .map { |p| p['label'] }
  end

  def degrees_dropdown
    string_matcher = resource.work_type == Work::Types.grad_culminating_experiences.first ? 'Doctor' : 'Master'
    Qa::Authorities::Local::FileBasedAuthority.new(:graduate_degrees)
      .all
      .filter_map { |p| p['label'] if p['label'].include? string_matcher }
  end
end
