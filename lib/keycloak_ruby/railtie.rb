# frozen_string_literal: true

module KeycloakRuby
  # Подключает middleware для быстрого логина в тестах.
  # Включается только если в конфиге стоит fast_test_login: true
  class Railtie < ::Rails::Railtie
    initializer "keycloak_ruby.test_login_middleware" do |app|
      if Rails.env.test? && KeycloakRuby.config.fast_test_login
        require "keycloak_ruby/testing/login_middleware"
        app.middleware.insert_before ActionDispatch::Flash, KeycloakRuby::Testing::LoginMiddleware
      end
    end
  end
end
