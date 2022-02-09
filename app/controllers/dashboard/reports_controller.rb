# frozen_string_literal: true

require 'csv'

class Dashboard::ReportsController < Dashboard::BaseController
  def show
  end

  def all_works
    report = AllWorksReport.new

    result = ::CSV.generate(headers: true) do |csv|
      csv << report.headers

      report.rows do |row|
        csv << row
      end
    end

    send_data result, filename: 'report.csv'
  end
end
