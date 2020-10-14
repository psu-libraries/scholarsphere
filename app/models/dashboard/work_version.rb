# frozen_string_literal: true

# @abstract Subclasses WorkVersion to allow for synchronus indexing. A Dashboard::WorkVersion is identical to a
# WorkVersion in every way, _except_ with respect to indexing. A WorkVersion is indexed async via ActiveJob, whereas
# the Dashboard::WorkVersion will update its index immediately. This is so any changes made by the user will appear in
# the dashboard as soon as a resource is created or update.
module Dashboard
  class WorkVersion < ::WorkVersion
    self.table_name = ::WorkVersion.table_name

    def self.model_name
      ::WorkVersion.model_name
    end

    private

      def update_index_with_callback
        update_index
      end
  end
end
