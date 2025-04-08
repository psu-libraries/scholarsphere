# frozen_string_literal: true

module Dashboard
  module Form
    class BaseController < ::Dashboard::BaseController
      include AllowPublish

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

        def process_response(on_error:, validation_context: nil, &block)
          respond_to do |format|
            if save_resource(validation_context: validation_context)
              yield if block
              format.html do
                redirect_upon_success
              end
            else
              # Rails 7 changed how it handles nested attributes. This removes all nested errors.
              @resource.errors.messages.each_key do |attribute|
                @resource.errors.delete(attribute) if attribute.to_s.include?('work.versions')
              end
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

        def request_accessibility_remediation?
          params.key?(:request_remediation)
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
          if save_and_exit? || finish? || request_curation? || request_accessibility_remediation?
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
          deposit_pathway.allows_curation_request? && in_publish_edit_action?
        end

        helper_method :allow_accessibility_remediation?
        def allow_accessibility_remediation?
          deposit_pathway.allows_accessibility_remediation_request? && in_publish_edit_action?
        end

        helper_method :allow_mint_doi?
        def allow_mint_doi?
          deposit_pathway.allows_mint_doi_request?
        end

        def allow_publish?
          super(@resource)
        end

        helper_method :param_key
        def param_key
          resource_klass.model_name.param_key
        end

        def in_publish_edit_action?
          current_controller = params[:controller]
          current_action = params[:action]

          current_controller == 'dashboard/form/publish' && ['edit', 'update'].include?(current_action)
        end

        helper_method :deposit_pathway
        def deposit_pathway
          @deposit_pathway ||= WorkDepositPathway.new(@work_version || @resource)
        end

        def save_resource(validation_context: nil)
          @resource.indexing_source = nil # uses the default source
          @resource.update_doi = (publish? || finish? || save_and_exit?)
          @resource.save(context: validation_context)
        end
    end
  end
end
