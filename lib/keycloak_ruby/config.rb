# frozen_string_literal: true

# lib/keycloak_ruby/config.rb
module KeycloakRuby
  # Configuration class for Keycloak Ruby gem.
  #
  # Handles loading and validation of Keycloak configuration from either:
  # - A YAML file (default: config/keycloak.yml)
  # - Direct attribute assignment
  #
  # == Example YAML Configuration
  #
  #   development:
  #     keycloak_url: "https://keycloak.example.com"
  #     app_host: "http://localhost:3000"
  #     realm: "my-realm"
  #     oauth_client_id: "my-client"
  #     oauth_client_secret: "secret"
  #
  # == Example Programmatic Configuration
  #
  #   config = KeycloakRuby::Config.new
  #   config.keycloak_url = "https://keycloak.example.com"
  #   config.realm = "my-realm"
  #   # ... etc
  # :reek:MissingSafeMethod
  class Config
    # Default path to configuration file (Rails.root/config/keycloak.yml)
    DEFAULT_CONFIG_PATH = if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
                            Rails.root.join("config", "keycloak.yml")
                          else
                            # Fallback for non-Rails or when Rails isn't loaded yet
                            File.expand_path("config/keycloak.yml", Dir.pwd)
                          end
    REQUIRED_ATTRIBUTES = %i[
      keycloak_url
      app_host
      realm
      oauth_client_id
      oauth_client_secret
    ].freeze

    # Default environment
    DEFAULT_ENV = "development"

    # :reek:Attribute
    attr_accessor :keycloak_url,
                  :app_host,
                  :realm,
                  :admin_client_id,
                  :admin_client_secret,
                  :oauth_client_id,
                  :oauth_client_secret

    attr_reader :config_path

    # Initialize configuration, optionally loading from YAML file
    #
    # @param config_path [String] Path to YAML config file (default: config/keycloak.yml)
    #
    #
    def initialize(config_path = DEFAULT_CONFIG_PATH)
      @config_path = config_path
      load_config
    end

    # Validates that all required configuration attributes are present
    #
    # @raise [KeycloakRuby::Errors::ConfigurationError] if any required attribute is missing
    #

    def validate!
      REQUIRED_ATTRIBUTES.each do |attr|
        value = public_send(attr)
        raise Errors::ConfigurationError, "#{attr} is required" if value.blank?
      end
    end

    def realm_url
      "#{keycloak_url}/realms/#{realm}"
    end

    def redirect_url
      "#{app_host}/auth/keycloak/callback"
    end

    def logout_url
      "#{realm_url}/protocol/openid-connect/logout"
    end

    def token_url
      "#{realm_url}/protocol/openid-connect/token"
    end

    private

    # Loads configuration from YAML file if it exists
    def load_config
      return unless File.exist?(@config_path)

      yaml_content = load_yaml_file
      env_config = yaml_content[current_env] || {}
      apply_config(env_config)
    end

    def load_yaml_file
      YAML.safe_load(ERB.new(File.read(@config_path)).result, aliases: true)
    rescue Errno::ENOENT, Psych::SyntaxError => e
      raise Errors::ConfigurationError, "Failed to load YAML from #{@config_path}: #{e.message}"
    end

    # Determines current environment
    #
    # @return [String] Current environment name
    # @api private
    def current_env
      @current_env ||= (defined?(Rails) && Rails.env) || ENV["APP_ENV"] || DEFAULT_ENV
    end

    # Applies configuration from hash
    #
    # @param config_hash [Hash] Configuration key-value pairs
    # @api private
    def apply_config(config_hash)
      config_hash.each do |key, value|
        setter = :"#{key}="
        begin
          public_send(setter, value)
        rescue NoMethodError
          # Silently ignore unknown configuration keys
          next
        end
      end
    end
  end
end
