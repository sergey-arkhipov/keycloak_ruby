# frozen_string_literal: true

# lib/keycloak_ruby/token_refresher.rb`
module KeycloakRuby
  # Handles OAuth2 refresh token flow with Keycloak
  #
  # Responsible for:
  # - Executing refresh token requests
  # - Validating responses
  # - Managing refresh failures
  #
  # @example Basic usage
  #   refresher = TokenRefresher.new(session, config)
  #   new_tokens = refresher.call
  #
  # @example With error handling
  #   begin
  #     refresher.call
  #   rescue KeycloakRuby::Errors::TokenRefreshFailed => e
  #     # Handle token refresh failure (e.g., redirect to login)
  #   end
  class TokenRefresher
    def initialize(session, config)
      @session = session
      @config = config
    end

    # Main entry point - refreshes the token
    # @return [Hash] New token data if successful
    # @raise [KeycloakRuby::Errors::TokenRefreshFailed] if refresh fails
    def call
      refresh_token_flow
    end

    private

    def refresh_token_flow
      log_refresh_attempt
      response = request_refresh
      validate_response(response)
    rescue HTTParty::Error => e
      handle_http_error(e)
    end

    def request_refresh
      HTTParty.post(
        @config.token_url,
        body: refresh_params,
        headers: headers,
        timeout: 30 # Add timeout for safety
      )
    end

    def validate_response(response)
      validator = ResponseValidator.new(response)

      if validator.validate
        log_successful_refresh
        validator.validate! # Returns the validated token data
      else
        handle_failed_validation(response)
      end
    end

    def handle_http_error(exception)
      error_message = "Token refresh HTTP error: #{exception.message}"
      KeycloakRuby.logger.error(error_message)
      raise Errors::TokenRefreshFailed, error_message
    end

    # :reek:FeatureEnvy
    def handle_failed_validation(response)
      error_message = "Token refresh failed. Status: #{response.code}, Body: #{response.body.truncate(200)}"
      KeycloakRuby.logger.error(error_message)
      raise Errors::TokenRefreshFailed, error_message
    end

    def refresh_params
      {
        grant_type: "refresh_token",
        client_id: @config.oauth_client_id,
        client_secret: @config.oauth_client_secret,
        refresh_token: @session[:refresh_token]
      }
    end

    def headers
      {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept" => "application/json",
        "User-Agent" => "KeycloakRuby/#{KeycloakRuby::Version::VERSION}"
      }
    end

    def log_refresh_attempt
      KeycloakRuby.logger.info("Attempting token refresh for client: #{@config.oauth_client_id}")
    end

    def log_successful_refresh
      KeycloakRuby.logger.info("Successfully refreshed tokens for client: #{@config.oauth_client_id}")
    end
  end
end
