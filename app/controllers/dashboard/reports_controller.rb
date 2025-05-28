# frozen_string_literal: true

require 'csv'

class Dashboard::ReportsController < Dashboard::BaseController
  before_action :authorize_report, except: [:index, :user_work_versions]

  def index; end

  def all_files
    generate_csv(AllFilesReport.new)
  end

  def all_works
    generate_csv(AllWorksReport.new)
  end

  def all_work_versions
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

  def user_work_versions
    depositor = Actor.find_by!(psu_id: current_user.actor.psu_id)
    start_date = Date.new(
      params[:report_start_date][:year].to_i,
      params[:report_start_date][:month].to_i,
      params[:report_start_date][:day].to_i
    )

    end_date = Date.new(
      params[:report_end_date][:year].to_i,
      params[:report_end_date][:month].to_i,
      params[:report_end_date][:day].to_i
    )

    if start_date > end_date
      flash.now[:error] = I18n.t('dashboard.reports.user_report.errors.end_before_start')
      render :index
    elsif start_date > Date.today || end_date > Date.today
      flash.now[:error] = I18n.t('dashboard.reports.user_report.errors.future_date')
      render :index
    else
      generate_csv(UserWorksReport.new(actor: depositor, start_date: start_date, end_date: end_date))
    end
  rescue Date::Error
    flash.now[:error] = I18n.t('dashboard.reports.user_report.errors.invalid_date')
    render :index
  end

  private

    def authorize_report
      deny_request unless current_user.admin?
    end

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
