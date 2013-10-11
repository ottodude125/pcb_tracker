source 'https://rubygems.org'

gem 'rails', '3.2.0'
gem "rack-cache", :git => "https://github.com/rtomayko/rack-cache.git"
#gem 'rake', '~> 0.9.2.2'
#gem 'rdoc', '~> 3.12'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-datatables-rails'
  gem 'jquery-ui-rails'
end

# Exception notifier for production mode
gem 'exception_notification', '2.6.1'

# jQuery
gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

# Java
gem 'execjs'
gem 'therubyracer'

# Graphs 
#gem 'gruff'
#gem 'rmagick'

# Autolink for messages
gem 'rails_autolink'

# Test coverage
#gem 'rcov'
#gem 'redgreen'

# LDAP
gem 'net-ldap'

group :test do
  # Pretty printed test outputtouch
  gem 'turn', '0.8.2', :require => false
end

group :development do
  gem "rails-erd" # generates schema diagrams by calling rake erd
  gem "railroady"
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request' # Required by RailsPanel which is a Chrome extension that will end your tailing of development.log
end

# Plugins to Gems
gem 'acts_as_list-rails3'

gem 'will_paginate'

gem 'piwik_analytics'

