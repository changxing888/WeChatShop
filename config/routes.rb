Rails.application.routes.draw do
  devise_for :users
  resources :users, only: [:index, :destroy]
  resources :chathistories, only: [:index]
  get 'home/about_us'
  get 'home/contact_us'

  mount API => '/'
  
  root 'home#index'
end
