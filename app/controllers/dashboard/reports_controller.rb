# frozen_string_literal: true

require 'csv'

class Dashboard::ReportsController < Dashboard::BaseController
  def show
  end

  def all_works
    generate_csv(AllWorksReport.new)
  end

  def all_work_versions
    generate_csv(AllWorkVersionsReport.new)
  end

  private

    def generate_csv(report)
      result = CSV.generate(headers: true) do |csv|
        csv << report.headers
  
        report.rows do |row|
          csv << row
        end
      end

      date = Time.now.strftime('%Y-%m-%d')
  
      send_data result, filename: "#{report.name}_#{date}.csv"
    end
end
