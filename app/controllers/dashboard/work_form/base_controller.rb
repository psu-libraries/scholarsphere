# frozen_string_literal: true

module Dashboard
  module WorkForm
    class BaseController < ::Dashboard::BaseController
      private

        def show_footer?
          false
        end

        def save_and_exit?
          params.key?(:save_and_exit)
        end

        def redirect_upon_success
          if save_and_exit?
            redirect_to resource_path(@work_version.uuid),
                        notice: 'Work version was successfully updated.'
          else
            redirect_to next_page_path
          end
        end

        def next_page_path
          raise NotImplementedError, 'You must implement this method in your controller subclass'
        end

        helper_method :cancel_path
        def cancel_path
          if @work_version.present? && @work_version.persisted?
            resource_path(@work_version.uuid)
          else
            dashboard_root_path
          end
        end

        def update_or_save_work_version(attributes: nil, index: true)
          @work_version.indexing_source = if index
                                            SolrIndexingJob.public_method(:perform_now)
                                          else
                                            null_indexer
                                          end

          if attributes
            @work_version.update(attributes)
          else
            @work_version.save
          end
        end

        def null_indexer
          Proc.new { nil }
        end
    end
  end
end
