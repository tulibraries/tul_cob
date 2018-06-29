# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "catalog#index"

  # concerns
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  # mounts
  mount Blacklight::Engine => "/"
  mount BlacklightAdvancedSearch::Engine => "/"
  mount BentoSearch::Engine => "/bento"

  # resource and resources
  resource :catalog, only: [:index], as: "catalog", path: "/catalog", controller: "catalog" do
    concerns :searchable
    concerns :range_searchable
  end

  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end

  resources :primo_central_documents, only: [:show], path: "/articles", controller: "primo_central" do
    concerns :exportable
  end

  post "catalog/:id/track" => "catalog#track"
  post "articles/:id/track" => "primo_central#track", as: :track_primo_central

  resources :users, only: [:index] do
    post :impersonate, on: :member
    post :stop_impersonating, on: :collection
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # auth
  authenticate do
    post "users/renew"

    get "users/account"

    get "users/fines"

    get "users/holds"

    get "users/loans"

    post "users/renew_selected"

    post "users/renew_all"

  end

  # gets
  get "bento" => "search#index", :as => "multi_search"
  get "catalog/:id/staff_view", to: "catalog#librarian_view", as: "staff_view"
  get "articles_advanced", to: "primo_advanced#index", as: "articles_advanced_search"

  get "catalog/:id/index_item", to: "catalog#index_item", as: "index_item"
  get "articles/:id/index_item", to: "primo_central#index_item", as: "articles_index_item"


  #
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  # we want helper methods for multi_search_path and multi_search_url
  # too, without removing root_url and root_path helpers. oddly, repeating
  # root seems to work.

  get "almaws/item/:mms_id", to:  "almaws#item", as: "item"

  scope module: "blacklight_alma" do
    get "alma/availability" => "alma#availability"
  end


  # matches
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/articles", to: "primo_central#index", as: "search", via: [:get, :post]

  Blacklight::Marc.add_routes(self)

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
