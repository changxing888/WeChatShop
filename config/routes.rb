Rails.application.routes.draw do
  mount API => '/'
  devise_for :users

  resources :products
  resources :orders
  resources :contacts, only: [:index, :new, :edit, :show]  
  
  resources :users, only: [:index, :destroy]
  resources :chathistories, only: [:index]

  get 'home/about_us'
  get 'home/contact_us'
  
  root 'home#index'
end
