Rails.application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    delete 'users/sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end
  
  post 'users/renew'

  get 'users/account'
  
  get 'users/fines'

  get 'users/holds'

  get 'users/loans'

  scope module: 'blacklight_alma' do
    get 'alma/availability' => 'alma#availability'
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

  Blacklight::Marc.add_routes(self)
  mount Blacklight::Engine => '/'
  root to: "catalog#index"
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

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
