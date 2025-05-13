# frozen_string_literal: true

# lib/keycloak_ruby.rb
require "omniauth"
require "omniauth_openid_connect"
require "httparty"
require "jwt"
require "zeitwerk"
require "omniauth/rails_csrf_protection/version"
require "omniauth/rails_csrf_protection/railtie" if defined?(Rails)
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
    # :reek:Attribute
    attr_writer :logger

    def logger
      @logger ||= resolve_logger
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

    private

    def resolve_logger
      if rails_defined? && rails_logger
        rails_logger
      else
        default_logger
      end
    end

    def rails_defined?
      defined?(Rails)
    end

    def rails_logger
      Rails.logger if rails_defined?
    rescue NoMethodError
      nil
    end

    def default_logger
      require "logger"
      Logger.new($stdout).tap { |log| log.level = Logger::INFO }
    end
  end
  # Load test helpers only in test environment
  if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test" || defined?(RSpec) || defined?(Minitest)
    require "keycloak_ruby/testing"
  end
end
