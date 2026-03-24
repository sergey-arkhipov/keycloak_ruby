# frozen_string_literal: true

# keycloak_ruby/testing/keycloak_helpers.rb
# :reek:UtilityFunction :reek:ControlParameter :reek:ManualDispatch :reek:BooleanParameter :reek:LongParameterList
module KeycloakRuby
  module Testing
    # Хелперы для тестов с Keycloak
    module KeycloakHelpers
      # Быстрый вход: если включён fast_test_login, для браузерных тестов
      # устанавливает сессию через middleware без OmniAuth.
      # Если флаг выключен — идёт через полный логин.
      # Для остальных типов тестов — мокирует TokenService.
      def sign_in(user, test_type: auto_detect_test_type)
        case test_type
        when :feature, :system
          fast_login_enabled? ? visit("/__test_login__/#{user.id}") : full_sign_in(user, test_type:)
        else
          mock_token_service(user)
        end
      end

      # Полная процедура входа через OmniAuth для тестов, которые проверяют сам логин.
      # Проходит /login → OmniAuth callback → SessionsController#create.
      def full_sign_in(user, test_type: auto_detect_test_type)
        case test_type
        when :request
          mock_token_service(user)
        when :feature, :system
          mock_keycloak_login(user, use_capybara: true)
        else
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

      # Удаление всех пользователей из Keycloak
      def self.delete_all_keycloak_users
        users = KeycloakRuby::User.find("") # Пустая строка — ищем всех
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
        config = OmniAuth.config
        config.test_mode = true
        token_data = generate_fake_tokens(user)
        config.mock_auth[:keycloak] = token_data

        use_capybara ? capybara_login : store_session(token_data.credentials)
      end

      def capybara_login
        visit "/login"
        translated_login_link = I18n.t("user.login")
        click_on translated_login_link if page.has_button? translated_login_link
      end

      def generate_fake_tokens(user)
        email = user.email
        expired_time =  2.hours.from_now.to_i
        token_payload = { "email" => email, "exp" => expired_time }

        OmniAuth::AuthHash.new(provider: "keycloak", uid: "uid-#{email}", info: { email: email },
                               credentials: OmniAuth::AuthHash.new(
                                 token: JWT.encode(token_payload, nil, "none"),
                                 refresh_token: "fake-refresh-#{email}",
                                 id_token: "fake-id-#{email}",
                                 expires_at: expired_time
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

      def fast_login_enabled?
        KeycloakRuby.config.fast_test_login
      end
    end
  end
end
# Автоматическое подключение хелперов в тестовые фреймворки
if defined?(RSpec)
  RSpec.configure do |config|
    config.include KeycloakRuby::Testing::KeycloakHelpers
  end
elsif defined?(Minitest)
  module Minitest
    # Подключение хелперов в Minitest
    class Test
      include KeycloakRuby::Testing::KeycloakHelpers
    end
  end
end
