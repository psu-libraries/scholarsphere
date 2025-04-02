module AllowPublish
    extend ActiveSupport::Concern
  
    included do
      helper_method :allow_publish? if respond_to?(:helper_method)
    end
    
    def allow_publish?(resource)
      deposit_pathway ||= WorkDepositPathway.new(resource)
      if deposit_pathway.work?
        (!resource.draft_curation_requested &&
          !resource.accessibility_remediation_requested &&
          !resource.file_version_memberships.any?(&:accessibility_score_pending?)) || current_user.admin?
      else
        true
      end
    end
  end