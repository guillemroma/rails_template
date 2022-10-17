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
Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.
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

  # Routes
  ########################################
  route "root to: 'pages#home'"

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

  inject_into_file 'app/views/pages/home.html.erb' do
    <<-HTML
      <div class="row">
        <div class="col-4"></div>
        <div class="col-4 mt-5">
          <div class="row mb-5">
            <h1 style="text-align:center"><strong>Log in</strong> as</h1>
          </div>
          <div class="row">
            <form action=<%= users_path %>>
              <button class = "btn btn-dark w-100" type="submit">
                  Admin
              </button>
            </form>
          </div>
          <div class="row mt-3">
            <form action=<%= new_dashboard_path %>>
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
