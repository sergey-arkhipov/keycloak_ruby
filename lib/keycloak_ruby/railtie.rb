# frozen_string_literal: true

module KeycloakRuby
  # Подключает middleware для быстрого логина в тестах
  class Railtie < ::Rails::Railtie
    initializer "keycloak_ruby.test_login_middleware" do |app|
      if Rails.env.test?
        require "keycloak_ruby/testing/login_middleware"
        app.middleware.insert_before ActionDispatch::Flash, KeycloakRuby::Testing::LoginMiddleware
      end
    end
  end
end
