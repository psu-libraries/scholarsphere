# frozen_string_literal: true

class MarkdownController < ApplicationController
  layout 'markdown'

  def show
    @page = params[:page]
    render params[:page]
  end
end
