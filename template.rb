run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    gem 'devise'

    gem 'autoprefixer-rails', '10.2.5'
    gem 'font-awesome-sass', '~> 5.6.1'
    gem 'simple_form', github: 'heartcombo/simple_form'

    gem "pundit"
    gem 'whenever', require: false
    gem 'pry', '~> 0.13.1'
    gem "factory_bot_rails"
    gem "sidekiq", "~> 6.5"
  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'dotenv-rails'
  gem 'rspec-rails'
  RUBY
end

gsub_file('Gemfile', /# gem 'redis'/, "gem 'redis'")

# Assets
########################################
run "rm -rf app/assets/stylesheets"
run "rm -rf vendor"
run "curl -L https://github.com/lewagon/rails-stylesheets/archive/no-update.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm -f stylesheets.zip && rm -f app/assets/rails-stylesheets-no-update/README.md"
run "mv app/assets/rails-stylesheets-no-update app/assets/stylesheets"

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
if Rails.version < "6"
  scripts = <<~HTML
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
        <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  HTML
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>", scripts)
end

gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")

style = <<~HTML
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)

# Navbar
########################################
file 'app/views/shared/_navbar.html.erb', <<~HTML
  <div class="navbar navbar-expand-sm navbar-light navbar-lewagon">
    <%= link_to "#", class: "navbar-brand" do %>
      <%= image_tag "https://raw.githubusercontent.com/lewagon/fullstack-images/master/uikit/logo.png" %>
    <% end %>

    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarSupportedContent">
      <% if user_signed_in? %>
        <%= image_tag "https://cdn.onlinewebfonts.com/svg/img_404623.png", class: "avatar dropdown-toggle", id: "navbarDropdown", data: { bs_toggle: "dropdown" }, 'aria-haspopup': true, 'aria-expanded': false %>
        <div class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
          <%= link_to "Log out", destroy_user_session_path, :method => :delete, class: "dropdown-item" %>
        </div>
      <% end %>
      </div>
  </div>
HTML

inject_into_file 'app/views/layouts/application.html.erb', after: '<body>' do
  <<-HTML

    <%= render 'shared/navbar' %>
  HTML
end

inject_into_file 'app/views/layouts/application.html.erb', before: '<%= yield %>' do
  <<-HTML
    <div class="yield-container">
  HTML
end

inject_into_file 'app/views/layouts/application.html.erb', after: '<%= yield %>' do
  <<-HTML
    </div>
  HTML
end

# README
########################################
markdown_file_content = <<-MARKDOWN
## Overview<br>
The app has been built using the following gems:

(1) **Pundit** for Authorization<br>
(2) **Devise** for Authentication<br>
(3) **Rspec** and **Factory Bot Rails** for Testing<br>
(4) **Whenever** to automate Tasks<br> [CHECK]
(5) **Sidekiq** to manage background Tasks<br> [CHECK]

## Pre-requisites<br>
Run the following commands:<br>

(1) bundle install<br>

(2.1) crontab -r<br> [CHECK]
(2.2) sudo service cron start<br> [CHECK]
(2.3) sudo service cron status -> make sure that it returns 'cron is running'<br> [CHECK]
(2.4) whenever --update-crontab --set environment='development'<br> [CHECK]

(3) sidekiq<br> [CHECK]

(4) rails db:prepare<br>

Seeds will ccreate an admin (user_type: "corporation") and 6 clients (user_type: "client") [CHECK]

## App's design and architecture<br>

### Authorization [CHECK]
Authorization is based on user_type ("client" or "corporation").

* A "client" user_type is only allowed to (1) access her own dashboard, (2) claim her rewards and (3) check her memberhsip.
* A "corporation" user_type can: (1) create new clients and edit existing ones, (2) create new transactions, (3) view client's points and transactions and (4) delete clients

### Models and its use
[FILL]

### Testing
Please refer to **spec** folder (disregard **test** folder)

## Next steps<br> [CHECK]
How can it be improved?

(1) If the app is finally released, multi-tenancy could be explored. The **Apartment** gem could be a great choice<br>
(2) Add **AuditLogs** to the most relevant transactions<br>
(3) Add **begin** and **resque** where applicable<br>
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')



  # Git ignore
  ########################################
  append_file '.gitignore', <<~TXT
    # Ignore .env file containing credentials.
    .env*
    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
    #{  "protect_from_forgery with: :exception\n" if Rails.version < "5.2"}  before_action :authenticate_user!
    end
  RUBY

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :home ]

      def home
      end
    end
  RUBY

  # Routes
  ########################################
  route "root to: 'pages#home'"

  inject_into_file 'config/routes.rb', after: 'Rails.application.routes.draw do' do
    devise_for :users, :path => 'u'
  end

  inject_into_file 'config/routes.rb', after: '# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html' do

    resources :users, only: [:new, :create, :show, :index, :edit, :update, :destroy]

    require "sidekiq/web"
    # authenticate :user, ->(user) { user.admin } do
    #   mount Sidekiq::Web => '/sidekiq'
    # end
  end

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  ########################################
  run 'yarn add bootstrap @popperjs/core'
  run "rails webpacker:install:stimulus"
  append_file 'app/javascript/packs/application.js', <<~JS
    import "bootstrap"
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
    <<~JS
      // Preventing Babel from transpiling NodeModules packages
      environment.loaders.delete('nodeModules');
    JS
  end

# Home page
########################################
run 'rm app/views/pages/home.html.erb'
create_file 'app/views/pages/home.html.erb' do
<<-HTML
<div class="row">
  <div class="col-4"></div>
  <div class="col-4 mt-5">
    <div class="row mb-5">
      <h1 style="text-align:center"><strong>Log in</strong> as</h1>
    </div>
    <div class="row">
      <form action=<%= root_path %>>
        <button class = "btn btn-dark w-100" type="submit">
            Admin
        </button>
      </form>
    </div>
    <div class="row mt-3">
      <form action=<%= root_path %>>
        <button class = "btn btn-dark w-100" type="submit">
            Client
        </button>
      </form>
    </div>
  </div>
</div>
HTML
end

  # Dotenv
  ########################################
  run 'touch .env'

  # Rubocop
  ########################################
  run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Git
  ########################################
  git add: '.'
  git commit: "-m 'Initial commit with basic setup'"
end
