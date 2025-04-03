# frozen_string_literal: true

# lib/keycloak_ruby/token_service.rb
# :reek:FeatureEnvy
module KeycloakRuby
  # Service for check and refresh jwt tokens
  class TokenService
    def initialize(session, config = KeycloakRuby::Config.new)
      @session = session
      @config = config
      @refresh_mutex = Mutex.new # Mutex ensures only one refresh happens at a time
    end

    # Finds user by token claims
    # @return [User, nil]
    def find_user
      claims = current_token or return
      user = ::User.find_by(email: claims["email"])
      clear_tokens unless user
      user
    end

    # Store token
    def store_tokens(data)
      @session[:access_token] = extract_access_token(data)
      @session[:refresh_token] = data["refresh_token"] if data["refresh_token"]
      @session[:id_token] = data["id_token"] if data["id_token"]
    end

    def clear_tokens
      %i[access_token refresh_token id_token].each { |token| @session.delete(token) }
    end

    private

    # It's necessary, because omniauth return request.env["omniauth.auth"] as 'token', not 'access_token'
    def extract_access_token(data)
      data["token"] || data["access_token"]
    end

    # Gets current token or attempts refresh if expired
    # @return [Hash, nil] Decoded token claims
    def current_token
      token = @session[:access_token] or return
      decode_token(token)
    rescue Errors::TokenExpired # Normal refresh
      refresh_current_token
    rescue Errors::TokenInvalid => e # Wrong token refresh
      Rails.logger.error("JWT Error: #{e.message}")
      clear_tokens
      nil
    end

    # Decodes JWT token
    # @raise [Errors::TokenExpired, Errors::TokenInvalid]
    def decode_token(token)
      options = jwt_decode_options

      if Rails.env.test?
        JWT.decode(token, nil, false).first # без проверки подписи в тестах
      else
        JWT.decode(token, nil, true, options).first
      end
    rescue JWT::ExpiredSignature => e
      raise Errors::TokenExpired, e.message
    rescue JWT::DecodeError => e
      raise Errors::TokenInvalid, e.message
    end

    def fetch_jwks
      realm_url = @config.realm_url
      @fetch_jwks ||= Rails.cache.fetch("keycloak_jwks", expires_in: 1.hour) do
        uri = URI("#{realm_url}/protocol/openid-connect/certs")
        JSON.parse(Net::HTTP.get(uri))
      end
    end

    # Attempts to refresh the current token
    def refresh_current_token
      @refresh_mutex.synchronize do
        new_tokens = TokenRefresher.new(@session, @config).call
        store_tokens(new_tokens)
        decode_token(new_tokens["access_token"])
      end
    rescue Errors::TokenRefreshFailed => e
      Rails.logger.error("Refresh failed: #{e.message}")
      clear_tokens
      nil
    end

    # JWT decoding options with JWKS
    def jwt_decode_options
      {
        algorithms: ["RS256"],
        verify_iss: true,
        iss: issuer_url,
        # verify_aud: true, # Вроде рекомендуют, но у нас не работает
        aud: @config.oauth_client_id,
        verify_expiration: true,
        jwks: fetch_jwks
      }
    end

    # Constructs issuer URL from configuration
    def issuer_url
      @issuer_url ||= @config.realm_url
    end
  end
end
