# lib/keycloak_ruby/errors.rb
module KeycloakRuby
  # Namespace for all KeycloakRuby specific errors
  # Follows a hierarchical structure for better error handling
  module Errors
    # Base error class for all KeycloakRuby errors
    # All custom errors inherit from this class
    class Error < StandardError; end

    ## Configuration Related Errors ##

    # Raised when there's an issue with gem configuration
    class ConfigurationError < Error; end

    ## Authentication Related Errors ##

    # Base class for authentication failures
    class AuthenticationError < Error; end

    # Raised when user credentials are invalid
    class InvalidCredentials < AuthenticationError; end

    # Raised when user account is not found
    class UserNotFound < AuthenticationError; end

    # Raised when account is temporarily locked
    class AccountLocked < AuthenticationError; end

    ## User Management Errors ##

    # Raised when user creation fails
    class UserCreationError < Error; end

    # Raised when user update fails
    class UserUpdateError < Error; end

    # Raised when user deletion fails
    class UserDeletionError < Error; end

    ## Token Related Errors ##

    # Base class for all token-related errors
    class TokenError < Error; end

    # Raised when token has expired +
    class TokenExpired < TokenError; end

    # Raised when token is invalid (malformed, wrong signature, etc.)
    class TokenInvalid < TokenError; end

    # Raised when token refresh fails
    class TokenRefreshFailed < TokenError; end

    # Raised when token verification fails
    class TokenVerificationFailed < TokenError; end

    ## API Communication Errors ##

    # Raised when API request fails
    class APIError < Error; end

    # Raised when receiving 4xx responses from Keycloak
    class ClientError < APIError; end

    # Raised when receiving 5xx responses from Keycloak
    class ServerError < APIError; end

    # Raised when connection to Keycloak fails
    class ConnectionError < APIError; end
  end
end
