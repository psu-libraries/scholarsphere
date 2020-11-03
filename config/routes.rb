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

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get 'sign_in', to: 'users/sessions#new', as: :new_user_session
    get 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :dashboard do
    root to: 'catalog#index'

    resource :catalog, only: [:index], as: 'catalog', path: 'catalog', controller: 'catalog' do
      concerns :searchable
    end

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

      get 'history', to: 'work_histories#show'
    end

    namespace :work_form, path: 'work-form' do # @todo change `path:` key once all of dashboard is converted
      get   'new', to: 'details#new'
      post  '/', to: 'details#create'

      get   ':work_version_id/details', to: 'details#edit', as: 'details'
      match ':work_version_id/details', to: 'details#update', via: %i[patch put], as: nil

      get   ':work_version_id/contributors', to: 'contributors#edit', as: 'contributors'
      match ':work_version_id/contributors', to: 'contributors#update', via: %i[patch put], as: nil

      get   ':work_version_id/files', to: 'files#edit', as: 'files'
      match ':work_version_id/files', to: 'files#update', via: %i[patch put], as: nil

      get   ':work_version_id/publish', to: 'publish#edit', as: 'publish'
      match ':work_version_id/publish', to: 'publish#update', via: %i[patch put], as: nil

      post 'aliases/new', to: 'aliases#new'
    end

    resources :collections
    resources :actors, only: [:new, :create]
  end

  namespace :api do
    namespace :v1 do
      resources :ingest, only: [:create]
      resources :collections, only: [:create]
      resources :files, only: [:update]
      resources :featured_resources, only: [:create]
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
