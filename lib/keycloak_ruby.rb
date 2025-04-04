# frozen_string_literal: true

require "omniauth"
require "omniauth_openid_connect"
require "httparty"
require "jwt"

# lib/keycloak_ruby.rb
require "generators/keycloak_ruby/install_generator" if defined?(Rails)
require "keycloak_ruby/authentication"
require "keycloak_ruby/client"
require "keycloak_ruby/config"
require "keycloak_ruby/errors"
require "keycloak_ruby/request_params"
require "keycloak_ruby/request_performer"
require "keycloak_ruby/response_validator"
require "keycloak_ruby/token_refresher"
require "keycloak_ruby/token_service"
require "keycloak_ruby/user"
require "keycloak_ruby/version"

# Module for interacting with Keycloak
module KeycloakRuby
  class << self
    # Logger used throughout the gem
    #
    # Defaults to Rails.logger if available, or a standard Logger.
    #
    # @return [Logger]
    attr_writer :logger

    def logger
      @logger ||= if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
                    Rails.logger
                  else
                    require "logger"
                    Logger.new($stdout).tap { |log| log.level = Logger::INFO }
                  end
    end

    # Returns the singleton configuration object. The configuration is
    # initialized on first access and validated immediately.
    #
    # @return [KeycloakRuby::Config] the configuration object
    def config
      @config ||= Config.new.tap(&:validate!)
    end

    # Yields the configuration object for block-based configuration.
    # Validates the configuration after the block executes.
    #
    # @yield [KeycloakRuby::Config] the configuration object
    # @raise [ConfigurationError] if configuration is invalid
    def configure
      yield config
      config.validate!
    end
  end
  VERSION = Version::VERSION
  # Only load test helpers when in test environment
  # Load test helpers only in test environment
  if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test" || defined?(RSpec) || defined?(Minitest)
    require "keycloak_ruby/testing"
  end
end
