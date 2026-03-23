# frozen_string_literal: true

module KeycloakRuby
  module Testing
    # Rack-middleware для быстрой аутентификации в тестах.
    # Записывает токены в сессию напрямую, минуя OmniAuth и Keycloak.
    #
    # Подключается автоматически в test-окружении через KeycloakRuby::Railtie.
    # Используется хелпером sign_in для браузерных тестов (:feature/:system).
    #
    # Было:  visit /login → рендер HTML → клик → OmniAuth → SessionsController → редирект
    # Стало: visit /__test_login__/123 → запись сессии → 204 No Content
    class LoginMiddleware
      TEST_LOGIN_PATH = %r{\A/__test_login__/(\d+)\z}

      def initialize(app)
        @app = app
      end

      def call(env)
        if (match = env["PATH_INFO"].match(TEST_LOGIN_PATH))
          handle_test_login(env, match[1].to_i)
        else
          @app.call(env)
        end
      end

      private

      def handle_test_login(env, user_id)
        user = ::User.find(user_id)
        email = user.email
        expired_time = 2.hours.from_now.to_i
        token_payload = { "email" => email, "exp" => expired_time }

        session = env["rack.session"]
        session[:access_token] = JWT.encode(token_payload, nil, "none")
        session[:refresh_token] = "fake-refresh-#{email}"
        session[:id_token] = "fake-id-#{email}"

        [204, {}, []]
      end
    end
  end
end
