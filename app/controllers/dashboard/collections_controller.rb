# frozen_string_literal: true

module Dashboard
  class CollectionsController < BaseController
    def index
      @collections = policy_scope(Collection)
        .includes(collection_work_memberships: { work: :versions })
    end

    def new
      @collection = new_collection
      @works = load_users_works
      @collection.build_creator_alias(actor: current_user.actor)
    end

    def create
      @collection = new_collection(collection_params)

      respond_to do |format|
        if @collection.save
          format.html do
            redirect_to dashboard_collections_path,
                        notice: 'Collection was successfully created.'
          end
          format.json { render :show, status: :created, location: @collection }
        else
          format.html { render :new }
          format.json { render json: @collection.errors, status: :unprocessable_entity }
        end
      end
    end

    def show
      @collection = policy_scope(Collection)
        .includes(collection_work_memberships: { work: :versions })
        .find(params[:id])
      authorize(@collection)
    end

    def edit
      @collection = policy_scope(Collection).find(params[:id])
      authorize(@collection)

      @works = load_users_works
      @collection.build_creator_alias(actor: current_user.actor)
    end

    def update
      @collection = policy_scope(Collection).find(params[:id])
      authorize(@collection)

      @collection.attributes = collection_params

      respond_to do |format|
        if @collection.save
          format.html do
            redirect_to dashboard_collection_path(@collection),
                        notice: 'Collection was successfully updated.'
          end
          format.json { render :show, status: :ok, location: @collection }
        else
          format.html { render :edit }
          format.json { render json: @collection.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @collection = policy_scope(Collection).find(params[:id])
      authorize(@collection)
      @collection.destroy
      respond_to do |format|
        format.html { redirect_to dashboard_collections_url, notice: 'Collection was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

      def new_collection(attrs = {})
        current_user.actor.deposited_collections.build(attrs)
      end

      def load_users_works
        current_user.works.includes(:versions)
      end

      def collection_params
        params
          .require(:collection)
          .permit(
            :title,
            :subtitle,
            work_ids: [],
            keyword: [],
            description: [],
            resource_type: [],
            contributor: [],
            publisher: [],
            published_date: [],
            subject: [],
            language: [],
            identifier: [],
            based_near: [],
            related_url: [],
            source: [],
            creator_aliases_attributes: [
              :id,
              :actor_id,
              :_destroy,
              :alias,
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
  end
end
