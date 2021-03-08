# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  default_url_options protocol: ENV.fetch('DEFAULT_URL_PROTOCOL', 'http'),
                      host: ENV.fetch('DEFAULT_URL_HOST', 'localhost')

  mount Qa::Engine => '/authorities'

  namespace :admin do
    authenticate :user do
      constraints ScholarsphereAdmin do
        mount Sidekiq::Web => '/sidekiq'

        get   'settings', to: 'application_settings#edit', as: :application_settings
        match 'settings', to: 'application_settings#update', via: %i[patch put]
      end
    end
  end

  mount OkComputer::Engine, at: '/health'
  mount Blacklight::Engine => '/'
  mount Shrine.uppy_s3_multipart(:cache) => '/s3/multipart'

  root to: 'pages#home'
  get 'about', to: 'markdown#show', page: 'about'
  get 'help', to: 'markdown#show', page: 'help'
  get 'policies-1.0', to: 'markdown#show', page: 'policies_1_0'
  get 'policies-2.0', to: 'markdown#show', page: 'policies_2_0'
  get 'policies', to: 'markdown#show', page: 'policies_2_0'
  get 'agreement-1.0', to: 'markdown#show', page: 'agreement_1_0'
  get 'agreement-2.0', to: 'markdown#show', page: 'agreement_2_0'
  get 'agreement', to: 'markdown#show', page: 'agreement_2_0'

  get 'contact', to: 'incidents#new'
  resources :incidents, only: [:new, :create]

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :resources, only: [:show] do
    get 'downloads/:id', to: 'downloads#content', as: :download
    get 'analytics', to: 'analytics#show', as: :analytics

    resource :doi, only: %i[create]
  end

  resources :sitemap, defaults: { format: :xml }, only: [:index, :show]

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # When using Devise with Omniauth for Azure integration, Azure does the logging in, and Devise handles the logging
  # out.  The latter amounts to just destroying the session; although a cached, valid, Azure session will still remain
  # in the user's browser.
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :dashboard do
    root to: 'catalog#index'

    resource :catalog, only: [:index], as: 'catalog', path: 'catalog', controller: 'catalog' do
      concerns :searchable
    end

    resources :collections, only: %i[edit update destroy]

    resource :profile, only: %i[edit update]

    resources :works, only: %i[edit update destroy] do
      resources :work_versions, except: [:new], shallow: true do
        get 'file_list', to: 'file_lists#edit'
        put 'file_list', to: 'file_lists#update'
        patch 'file_list', to: 'file_lists#update'

        get 'publish', to: 'work_versions#publish'

        get 'diff/:previous_version_id', to: 'work_versions#diff', as: :diff

        resources :files,
                  controller: :file_version_memberships,
                  only: %i(edit update destroy),
                  shallow: true
      end
    end

    namespace :form do
      scope 'work_versions' do
        get   'new', to: 'work_version_details#new', as: 'work_versions'
        match 'new', to: 'work_version_details#create', via: :post, as: nil

        get   ':id/details', to: 'work_version_details#edit', as: 'work_version_details'
        match ':id/details', to: 'work_version_details#update', via: %i[patch put], as: nil

        get   ':id/files', to: 'files#edit', as: 'files'
        match ':id/files', to: 'files#update', via: %i[patch put], as: nil

        get   ':id/publish', to: 'publish#edit', as: 'publish'
        match ':id/publish', to: 'publish#update', via: %i[patch put], as: nil
      end

      scope 'collections' do
        get   'new', to: 'collection_details#new', as: 'collections'
        match 'new', to: 'collection_details#create', via: :post, as: nil

        get   ':id/details', to: 'collection_details#edit', as: 'collection_details'
        match ':id/details', to: 'collection_details#update', via: %i[patch put], as: nil
        match ':id/details', to: 'collection_details#destroy', via: :delete, as: nil

        get   ':id/members', to: 'members#edit', as: 'members'
        match ':id/members', to: 'members#update', via: %i[patch put], as: nil

        post ':id/work_memberships/new', to: 'work_memberships#new', as: 'collection_memberships'
      end

      # Routes common to both work versions and collections

      get   ':resource_klass/:id/contributors', to: 'contributors#edit', as: 'contributors'
      match ':resource_klass/:id/contributors', to: 'contributors#update', via: %i[patch put], as: nil

      post ':resource_klass/:id/authorships/new', to: 'authorships#new', as: 'authorships'
    end
  end

  namespace :api do
    namespace :v1 do
      resources :ingest, only: [:create]
      resources :collections, only: [:create]
      resources :files, only: [:update]
      resources :featured_resources, only: [:create]
      resources :uploads, only: [:create]
    end
  end

  get '/404', to: 'errors#not_found'
  get '/401', to: 'errors#not_found'
  get '/500', to: 'errors#server_error'

  # Legacy URL support
  # Note that collections and works go to the same place. This works because the
  # legacy IDs are unique noids. It could lead to an extraordinarily unlikely
  # false positive, but it would never lead to a false negative.
  get '/concern/generic_works/:id', to: 'legacy_urls#v3'
  get '/collections/:id', to: 'legacy_urls#v3'
end
