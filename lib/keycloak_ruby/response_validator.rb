# frozen_string_literal: true

module KeycloakRuby
  # Validates Keycloak API responses with both safe and strict modes
  #
  # Provides two validation approaches:
  # 1. Safe validation (#validate) - returns boolean
  # 2. Strict validation (#validate!) - raises detailed exceptions
  #
  # @example Safe validation
  #   validator = ResponseValidator.new(response)
  #   if validator.validate
  #     # proceed with valid response
  #   else
  #     # handle invalid response
  #   end
  #
  # @example Strict validation
  #   begin
  #     data = ResponseValidator.new(response).validate!
  #     # use validated data
  #   rescue KeycloakRuby::Errors::TokenRefreshFailed => e
  #     # handle error
  #   end
  class ResponseValidator
    # Initialize with the HTTP response
    # @param response [HTTP::Response] The raw HTTP response from Keycloak
    def initialize(response)
      @response = response
      @data = parse_response_body
    end

    # Safe validation - returns boolean instead of raising exceptions
    # @return [Boolean] true if response is valid, false otherwise
    def validate
      return false unless valid_http_status?
      return false if invalid_grant?
      return false if error_present?

      access_token_present?
    end

    # Strict validation - raises exceptions for invalid responses
    # @return [Hash] Parsed response data if valid
    # @raise [KeycloakRuby::Errors::TokenRefreshFailed] if validation fails
    def validate!
      validate or raise_validation_error
      @data
    end

    private

    # Parses JSON response body, returns empty hash on failure
    # @return [Hash]
    def parse_response_body
      JSON.parse(@response.body)
    rescue JSON::ParserError
      {}
    end

    # Checks if HTTP status indicates success
    # @return [Boolean]
    def valid_http_status?
      @response.success?
    end

    # Checks for OAuth2 "invalid_grant" error
    # @return [Boolean]
    def invalid_grant?
      @data["error"] == "invalid_grant"
    end

    # Checks for any error in response
    # @return [Boolean]
    def error_present?
      @data.key?("error")
    end

    # Verifies access token presence
    # @return [Boolean]
    def access_token_present?
      @data["access_token"].present?
    end

    # Raises appropriate validation error based on failure reason
    # @raise [KeycloakRuby::Errors::TokenRefreshFailed]
    def raise_validation_error # rubocop:disable Metrics/MethodLength
      error_description = @data["error_description"]
      if !valid_http_status?
        raise Errors::TokenRefreshFailed,
              "Keycloak API request failed with status #{@response.code}: #{extract_error_message}"
      elsif invalid_grant?
        raise Errors::TokenRefreshFailed,
              "Invalid grant: #{error_description || "Refresh token invalid or expired"}"
      elsif error_present?
        raise Errors::TokenRefreshFailed,
              "Keycloak error: #{@data["error"]} - #{error_description}"
      else
        raise Errors::TokenRefreshFailed,
              "Invalid response: access token missing from response"
      end
    end

    # Extracts error message from response
    # @return [String]
    def extract_error_message
      error_description = @data["error_description"]
      response_body = @response.body
      if error_description
        error_description
      elsif response_body.length < 100 # Prevent huge error messages
        response_body
      else
        "See response body for details"
      end
    end
  end
end
