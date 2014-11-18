source 'https://rubygems.org'

ruby '2.1.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.2'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

gem 'mysql2'

gem 'bootstrap-sass'
gem 'haml-rails'
gem 'haml2slim'
gem 'html2haml'
gem 'devise'
gem 'thin'
gem 'binding_of_caller'

group :assets do
  # Use Uglifier as compressor for JavaScript assets
  gem 'uglifier', '>= 1.3.0'
  # Use CoffeeScript for .js.coffee assets and views
  gem 'coffee-rails', '~> 4.0.0'
  # Use SCSS for stylesheets
  gem 'sass-rails', '~> 4.0.3'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer',  platforms: :ruby
  # gem 'rails-assets-bootstrap'
end

group :development do
  gem 'better_errors'  
  gem 'hub', :require=>nil
  gem 'quiet_assets'
  gem 'rails_layout'
  # gem 'debugger'
  gem 'letter_opener'
end
group :development, :test do
  gem 'factory_girl_rails'
  gem 'pry-rails'
  gem 'pry-rescue'
  gem 'rspec-rails'
  gem 'railroady'
  # gem 'sdoc', require: false
end

group :test do
  gem 'capybara'
  gem 'database_cleaner', '1.0.1'
  gem 'email_spec'
  gem 'mongoid-rspec', '>= 1.10.0'
end

group :production, :heroku do
  gem 'rails_12factor'
end