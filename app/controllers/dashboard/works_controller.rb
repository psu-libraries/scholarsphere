# frozen_string_literal: true

class Dashboard::WorksController < Dashboard::BaseController
  # GET /works
  # GET /works.json
  def index
    @works = current_user.works.includes(:versions).map do |work|
      Dashboard::WorkDecorator.new(work)
    end
  end

  # GET /works/new
  def new
    @work = Work.build_with_empty_version
  end

  # POST /works
  # POST /works.json
  def create
    @work = current_user.works.build(work_params)

    respond_to do |format|
      if @work.save
        format.html do
          # WIP redirect_to work_version_file_list_path(@work, @work.versions.last),
          redirect_to dashboard_works_path,
                      notice: 'Work was successfully created.'
        end
        format.json { render :show, status: :created, location: @work }
      else
        format.html { render :new }
        format.json { render json: @work.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /works/1
  # DELETE /works/1.json
  def destroy
    @work = current_user.works.find(params[:id])
    @work.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_works_url, notice: 'Work was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def work_params
      params
        .require(:work)
        .permit(
          :work_type,
          versions_attributes: [
            :title
          ]
        )
    end
end
