# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "search#index"

  # advanced forms
  match "/books/advanced", to: "books_advanced#index", as: "books_advanced_search", via: [:get, :post]
  match "journals/advanced", to: "journals_advanced#index", as: "journals_advanced_search", via: [:get, :post]
  match "databases/advanced", to: "databases_advanced#index", as: "databases_advanced_search", via: [:get, :post]
  match "articles/advanced", to: "primo_advanced#index", as: "articles_advanced_search", via: [:get, :post]
  match "catalog/advanced", to: "advanced#index", as: "advanced_search", via: [:get, :post]
  match "catalog/:id/purchase_order", to: "catalog#purchase_order_action", via: [:post], as: "purchase_order_action"

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

  resource :books, only: [:index], as: "books", path: "/books", controller: "books" do
    concerns :searchable
    concerns :range_searchable
  end

  resource :journals, only: [:index], as: "journals", path: "/journals", controller: "journals" do
    concerns :searchable
    concerns :range_searchable
  end

  resource :databases, only: [:index], as: "databases", path: "/databases", controller: "databases" do
    concerns :searchable
    concerns :range_searchable
  end

  resource :web_content, only: [:index], as: "web_content", path: "/web_content", controller: "web_content" do
    concerns :searchable
    #concerns :range_searchable
  end

  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
  end

  resources :solr_book_documents, only: [:show], path: "/books", controller: "books" do
    concerns :exportable
  end

  resources :solr_journal_documents, only: [:show], path: "/journals", controller: "journals" do
    concerns :exportable
  end

  resources :solr_database_documents, only: [:show], path: "/databases", controller: "databases" do
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
  post "books/:id/track" => "book#track"
  post "journals/:id/track" => "journal#track"
  post "databases/:id/track" => "databases#track"

  devise_for :users, controllers: { sessions: "sessions", omniauth_callbacks: "users/omniauth_callbacks" }

  devise_scope :user do
    get "alma/social_login_callback" => "sessions#social_login_callback"
  end

  # auth
  authenticate do
    post "users/renew"

    get "users/account"

    get "users/fines", as: "user_fines"

    get "users/holds", as: "user_holds"

    get "users/loans", as: "user_loans"

    post "users/renew_selected"

    post "users/renew_all"

  end

  # gets
  get "bento" => "search#index", :as => "multi_search"
  get "everything" => "search#index", :as => "everything"
  get "catalog/:id/staff_view", to: "catalog#librarian_view", as: "staff_view"
  get "articles_advanced", to: "primo_advanced#index", as: "legacy_articles_advanced_search"

  get "catalog/:id/index_item", to: "catalog#index_item", as: "index_item"
  get "books/:id/index_item", to: "books#index_item", as: "book_item"
  get "journals/:id/index_item", to: "journals#index_item", as: "journal_item"
  get "databases/:id/index_item", to: "databases#index_item", as: "database_item"
  get "articles/:id/index_item", to: "primo_central#index_item", as: "articles_index_item"
  get "catalog/:id/purchase_order", to: "catalog#purchase_order", as: "purchase_order"


  #
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  # we want helper methods for multi_search_path and multi_search_url
  # too, without removing root_url and root_path helpers. oddly, repeating
  # root seems to work.

  get "almaws/item/:mms_id", to:  "almaws#item", as: "item"
  get "almaws/request/:mms_id/:pickup_location/:request_level", to: "almaws#request_options", as: "request_options"
  post "almaws/request/digitization", to: "almaws#send_digitization_request", as: "digitization_request"
  post "almaws/request/hold", to: "almaws#send_hold_request", as: "hold_request"
  post "almaws/request/booking", to: "almaws#send_booking_request", as: "booking_request"

  scope module: "blacklight_alma" do
    get "alma/availability" => "alma#availability"
  end


  # matches
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/articles", to: "primo_central#index", as: "search", via: [:get, :post]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
