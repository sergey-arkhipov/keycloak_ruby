# frozen_string_literal: true

# lib/keycloak_ruby.rb
require "omniauth"
require "omniauth_openid_connect"
require "httparty"
require "jwt"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore(
  "#{__dir__}/generators",
  "#{__dir__}/templates"
)
loader.setup

require "generators/keycloak_ruby/install_generator" if defined?(Rails)

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
  # Load test helpers only in test environment
  if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test" || defined?(RSpec) || defined?(Minitest)
    require "keycloak_ruby/testing"
  end
end
