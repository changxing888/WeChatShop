Rails.application.routes.draw do
  devise_for :users
  
  get 'home/about_us'
  get 'home/contact_us'
  root 'home#index'
end
