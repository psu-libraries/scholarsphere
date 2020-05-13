# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
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
  root to: 'catalog#index'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :resources, only: [:show] do
    get 'downloads/:id', to: 'downloads#content', as: :download
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
    resource :profile, only: %i[edit update]

    resources :works, only: %i[index new create destroy] do
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

    resources :collections
  end

  namespace :api do
    namespace :v1 do
      resources :ingest, only: [:create]
      resources :collections, only: [:create]
    end
  end

  # Legacy URL support
  get '/concern/generic_works/:id', to: 'legacy_urls#v3'
end
