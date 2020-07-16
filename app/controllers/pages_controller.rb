# frozen_string_literal: true

class PagesController < ApplicationController
  def home
    @featured_works = work_versions.map { |work_version| ResourceDecorator.new(work_version) }
  end

  private

    def determine_layout
      'frontend'
    end

    # @note for now, just grab three randomly published work versions
    def work_versions
      WorkVersion.where(aasm_state: 'published').order(Arel.sql('RANDOM()')).limit(3)
    end
end
