# frozen_string_literal: true

# keycloak_ruby/testing/keycloak_helpers.rb
# :reek:UtilityFunction :reek:ControlParameter :reek:ManualDispatch :reek:BooleanParameter :reek:LongParameterList
module KeycloakRuby
  module Testing
    # Helper module for tests with Keycloak
    module KeycloakHelpers
      # Combines both sign-in approaches with automatic detection of test type
      def sign_in(user, test_type: auto_detect_test_type)
        case test_type
        when :request
          mock_token_service(user)
        when :feature, :system
          mock_keycloak_login(user, use_capybara: true)
        else # :controller, :view, etc.
          mock_keycloak_login(user, use_capybara: false)
        end
      end

      # Мокирует авторизацию в request-тестах, подставляя указанного пользователя в current_user.
      # Нужно, так как в request-тестах нет прямого доступа к сессиям и внешним сервисам авторизации.
      def mock_token_service(user)
        token_service_double = instance_double(KeycloakRuby::TokenService, find_user: user)
        allow(KeycloakRuby::TokenService).to receive(:new).and_return(token_service_double)
      end

      def create_keycloak_user(username:, email:, password:, temporary:)
        user_data = KeycloakRuby::User.create(username:, email:, password:, temporary:)
        KeycloakHelpers.track_keycloak_user(user_data["id"])
        user_data
      end

      # Delete all users from Keycloak
      def self.delete_all_keycloak_users
        users = KeycloakRuby::User.find("") # Empty search string to find all users
        users.each do |user|
          KeycloakRuby::User.delete_by_id(user["id"])
        end
      end

      def self.track_keycloak_user(user_id)
        @keycloak_users ||= []
        @keycloak_users << user_id
      end

      def self.cleanup_keycloak_users
        return unless @keycloak_users

        @keycloak_users.each do |user_id|
          KeycloakRuby::User.delete(user_id)
        end
        @keycloak_users.clear
      end

      private

      def mock_keycloak_login(user, use_capybara: true)
        OmniAuth.config.test_mode = true
        token_data = generate_fake_tokens(user)
        OmniAuth.config.mock_auth[:keycloak] = token_data

        if use_capybara
          capybara_login
        else
          store_session(token_data.credentials)
        end
      end

      def capybara_login
        visit "/login"
        click_on I18n.t("user.login") if page.has_button? I18n.t("user.login")
      end

      def generate_fake_tokens(user)
        email = user.email
        token_payload = { "email" => email, "exp" => 2.hours.from_now.to_i }

        OmniAuth::AuthHash.new(provider: "keycloak", uid: "uid-#{email}", info: { email: email },
                               credentials: OmniAuth::AuthHash.new(
                                 token: JWT.encode(token_payload, nil, "none"),
                                 refresh_token: "fake-refresh-#{email}",
                                 id_token: "fake-id-#{email}",
                                 expires_at: 2.hours.from_now.to_i
                               ))
      end

      def store_session(credentials)
        session[:access_token]  = credentials[:token]
        session[:refresh_token] = credentials[:refresh_token]
        session[:id_token]      = credentials[:id_token]
      end

      def rspec_auto_detect_test_type
        if RSpec.current_example.metadata[:type] == :request
          :request
        elsif defined?(Capybara::DSL) && Capybara.current_driver != :rack_test
          :feature
        else
          :controller
        end
      end

      def auto_detect_test_type
        if defined?(RSpec) && RSpec.current_example
          rspec_auto_detect_test_type
        else
          :feature
        end
      end
    end
  end
end
# Automatically include in common test frameworks
if defined?(RSpec)
  RSpec.configure do |config|
    config.include KeycloakRuby::Testing::KeycloakHelpers
  end
elsif defined?(Minitest)
  module Minitest
    class Test
      include KeycloakRuby::Testing::KeycloakHelpers
    end
  end
end
