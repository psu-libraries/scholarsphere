# frozen_string_literal: true

module Dashboard
  module Form
    class BaseController < ::Dashboard::BaseController
      private

        def resource_klass
          case params[:resource_klass]
          when 'work_version'
            WorkVersion
          when 'collection'
            Collection
          else
            @resource.class
          end
        end

        # where drafts are being saved
        def process_response(on_error:, validation_context: nil)
          respond_to do |format|
            if save_resource(validation_context: validation_context)
              format.html do
                redirect_upon_success
              end
            else
              format.html { render on_error }
            end
          end
        end

        def show_footer?
          false
        end

        def save_and_exit?
          params.key?(:save_and_exit)
        end

        def request_curation?
          params.key?(:request_curation)
        end

        def create?
          @resource.new_record?
        end

        def publish?
          params.key?(:publish)
        end

        def finish?
          params.key?(:finish)
        end

        def redirect_upon_success
          if save_and_exit? || finish? || request_curation?
            redirect_to resource_path(@resource.uuid),
                        notice: I18n.t('dashboard.form.notices.success', resource: @resource.model_name.human)
          elsif publish?
            redirect_to resource_path(@resource.work.uuid),
                        notice: I18n.t('dashboard.form.notices.publish')
          else
            redirect_to next_page_path
          end
        end

        def next_page_path
          raise NotImplementedError, 'You must implement this method in your controller subclass'
        end

        helper_method :cancel_path
        def cancel_path
          if @resource.present? && @resource.persisted?
            resource_path(@resource.uuid)
          else
            dashboard_root_path
          end
        end

        helper_method :allow_curation?
        def allow_curation?
          curation_eligible? && in_publish_edit_action?
        end

        helper_method :allow_publish?
        def allow_publish?
          if @resource.is_a?(Collection)
            true
          else
            !@resource.draft_curation_requested
          end
        end

        helper_method :param_key
        def param_key
          resource_klass.model_name.param_key
        end

        def in_publish_edit_action?
          current_controller = params[:controller]
          current_action = params[:action]

          current_controller == 'dashboard/form/publish' && current_action == 'edit'
        end

        def data?
          @resource.work.work_type == 'dataset' || @resource.work.work_type == 'software_or_program_code'
        end

        def curation_eligible?
          !@resource.is_a?(Collection) && !@resource.draft_curation_requested && data?
        end

        def save_resource(validation_context: nil)
          @resource.indexing_source = nil # uses the default source
          @resource.update_doi = (publish? || finish? || save_and_exit?)
          @resource.save(context: validation_context)
        end
    end
  end
end
