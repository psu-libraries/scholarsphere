# frozen_string_literal: true

class MarkdownController < ApplicationController
  def show
    @page = params[:page]
    render params[:page]
  end

  private

    def determine_layout
      'markdown'
    end
end
