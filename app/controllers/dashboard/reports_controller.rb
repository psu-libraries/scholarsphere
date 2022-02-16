# frozen_string_literal: true

require 'csv'

class Dashboard::ReportsController < Dashboard::BaseController
  def show; end

  def all_files
    return deny_request unless current_user.admin?

    generate_csv(AllFilesReport.new)
  end

  def all_works
    return deny_request unless current_user.admin?

    generate_csv(AllWorksReport.new)
  end

  def all_work_versions
    return deny_request unless current_user.admin?

    generate_csv(AllWorkVersionsReport.new)
  end

  def monthly_work_versions
    date = Date.new(
      params[:report_date][:year].to_i,
      params[:report_date][:month].to_i,
      params[:report_date][:day].to_i
    )

    generate_csv(MonthlyWorksReport.new(date: date))
  end

  def monthly_user_work_versions
    depositor = Actor.find_by!(psu_id: params['psu_id'])
    date = Date.new(
      params[:report_date][:year].to_i,
      params[:report_date][:month].to_i,
      params[:report_date][:day].to_i
    )

    generate_csv(MonthlyUserWorksReport.new(actor: depositor, date: date))
  end

  private

    def deny_request
      render json: { message: I18n.t('errors.not_authorized.heading'), code: 401 }, status: 401
    end

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
