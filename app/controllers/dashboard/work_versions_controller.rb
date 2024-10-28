# frozen_string_literal: true

module Dashboard
  class WorkVersionsController < BaseController
    def create
      work = Work.find(params[:work_id])
      authorize(work, :create_version?)

      @work_version = BuildNewWorkVersion.call(work.representative_version)

      respond_to do |format|
        if @work_version.save
          format.html do
            redirect_to dashboard_form_work_version_details_path(@work_version),
                        notice: 'Work version was successfully created.'
          end
          format.json { render :show, status: :created, location: @work_version }
        else
          # _Highly_ unlikely this branch could ever be hit, since
          # the latest version needs to be valid in order to be published
          format.html do
            redirect_to dashboard_root_path,
                        error: 'Work version could not be created: ' +
                          @work_version.errors.full_messages.join(', ')
          end
          format.json { render json: @work_version.errors, status: :unprocessable_entity }
        end
      end
    end

    def show
      @work_version = WorkVersionDecorator.new(WorkVersion.find(params[:id]))
      authorize(@work_version)
      @work = WorkDecorator.new(@work_version.work)
    end

    def edit
      @work_version = WorkVersion.find(params[:id])
      authorize(@work_version)

      @work_version.build_creator(actor: current_user.actor)
    end

    def update
      @work_version = WorkVersion.find(params[:id])
      authorize(@work_version)

      # There is be a better way to do this, but I think it's decent enough for now
      if params.key?(:publish)
        update_publish
      else
        update_metadata
      end
    end

    def destroy
      @work_version = WorkVersion.find(params[:id])
      authorize(@work_version)

      parent_work = DestroyWorkVersion.call(
        @work_version, force: current_user.admin?
      )

      redirect_path = if parent_work.nil?
                        dashboard_root_path
                      else
                        resource_path(parent_work.latest_version.uuid)
                      end

      respond_to do |format|
        format.html { redirect_to redirect_path, notice: 'Work version was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    def publish
      @work_version = WorkVersion.find(params[:work_version_id])
      authorize(@work_version)
    end

    def diff
      current_version = WorkVersion.find(params[:work_version_id])
      previous_version = WorkVersion.find(params[:previous_version_id])
      authorize(current_version) && authorize(previous_version)

      @work_version = WorkVersionDecorator.new(current_version)
      @previous_version = WorkVersionDecorator.new(previous_version)
      @work = WorkDecorator.new(@work_version.work)
      @presenter = DiffPresenter.new(
        MetadataDiff.call(@previous_version, @work_version),
        file_diff: FileVersionMembershipDiff.call(@previous_version, @work_version),
        creator_diff: AuthorshipDiff.call(@previous_version, @work_version)
      )
    end

    private

      def update_publish
        @work_version.attributes = publish_params
        @work_version.publish

        respond_to do |format|
          if @work_version.save
            format.html do
              redirect_to dashboard_root_path, notice: 'Successfully published work!'
            end
            format.json { render :show, status: :ok, location: @work_version }
          else
            format.html { render :publish }
            format.json { render json: @work_version.errors, status: :unprocessable_entity }
          end
        end
      end

      def update_metadata
        @work_version.attributes = metadata_params

        respond_to do |format|
          if @work_version.save
            format.html do
              redirect_to dashboard_work_version_publish_path(@work_version),
                          notice: 'Work version was successfully updated.'
            end
            format.json { render :show, status: :ok, location: @work_version }
          else
            format.html { render :edit }
            format.json { render json: @work_version.errors, status: :unprocessable_entity }
          end
        end
      end

      def metadata_params
        params
          .require(:work_version)
          .permit(
            :title,
            :description,
            :subtitle,
            :rights,
            :version_name,
            :published_date,
            :sub_work_type,
            :program,
            :degree,
            keyword: [],
            contributor: [],
            publisher: [],
            subject: [],
            language: [],
            identifier: [],
            based_near: [],
            related_url: [],
            source: [],
            creators_attributes: [
              :id,
              :actor_id,
              :_destroy,
              :display_name,
              actor_attributes: [
                :id,
                :email,
                :given_name,
                :surname,
                :psu_id
              ]
            ]
          )
      end

      def publish_params
        params
          .require(:work_version)
          .permit(
            :depositor_agreement,
            :psu_community_agreement,
            :accessibility_agreement,
            :sensitive_info_agreement
          )
      end
  end
end
