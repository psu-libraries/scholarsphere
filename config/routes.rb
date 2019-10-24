# frozen_string_literal: true

Rails.application.routes.draw do
  mount Blacklight::Engine => '/'
  mount Shrine.uppy_s3_multipart(:cache) => '/s3/multipart'
  root to: 'catalog#index'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
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
end
