# frozen_string_literal: true

class CuratorForm
    include ActiveModel::Model
  
    attr_reader :resource
  
    def initialize(resource:, params:)
      @resource = resource
      super(params)
    end
  
    def access_id
      @access_id ||= current_curator_access_id
    end
  
    def access_id=(access_id)
      @access_id = access_id
    end
  
    def save
      add_curator
      return false if errors.present?
  
      resource.save
    end
  
    private
  
      def add_curator
        user = User.find_by(access_id: @access_id)
        Curatorship.create(user: user, work: resource)
        unless user.present?
          errors.add(:access_id, :not_found, access_id: @access_id)
        end
      end

      def current_curator_access_id
        resource.curatorships.order(created_at: :desc)&.first&.access_id
      end
  end
  