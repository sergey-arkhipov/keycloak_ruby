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
    DEFAULT_CONFIG_PATH = if defined?(Rails) && Rails.respond_to?(:root)
                            Rails.root.join("config", "keycloak.yml")
                          else
                            File.expand_path("config/keycloak.yml", __dir__)
                          end
    # :reek:Attribute
    attr_accessor :keycloak_url, :app_host, :realm, :admin_client_id,
                  :admin_client_secret, :oauth_client_id, :oauth_client_secret,
                  :realm_url, :redirect_url, :logout_url, :token_url

    # Initialize configuration, optionally loading from YAML file
    #
    # @param config_path [String] Path to YAML config file (default: config/keycloak.yml)
    #
    #
    def initialize(config_path = DEFAULT_CONFIG_PATH)
      @config_path = config_path
      load_config
      set_derived_values
    end

    # Validates that all required configuration attributes are present
    #
    # @raise [KeycloakRuby::Errors::ConfigurationError] if any required attribute is missing
    #

    def validate!
      required_attributes.each do |attr, value|
        raise KeycloakRuby::Errors::ConfigurationError, "#{attr} is required" if value.blank?
      end
    end

    private

    # Loads configuration from YAML file if it exists
    # :reek:ManualDispatch
    def load_config
      return unless File.exist?(@config_path)

      yaml = YAML.safe_load(ERB.new(File.read(@config_path)).result, aliases: true)[Rails.env]
      yaml.each do |key, value|
        public_send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
    end

    # Sets derived URLs based on base configuration
    def set_derived_values
      @redirect_url = "#{app_host}/auth/keycloak/callback"
      @logout_url = "#{keycloak_url}/realms/#{realm}/protocol/openid-connect/logout"
      @realm_url = "#{keycloak_url}/realms/#{realm}"
      @token_url = "#{keycloak_url}/realms/#{realm}/protocol/openid-connect/token"
    end

    # Defines which attributes are required for validation
    def required_attributes # rubocop:disable Metrics/MethodLength
      {
        keycloak_url: keycloak_url,
        app_host: app_host,
        realm: realm,
        oauth_client_id: oauth_client_id,
        oauth_client_secret: oauth_client_secret,
        realm_url: realm_url,
        redirect_url: redirect_url,
        logout_url: logout_url,
        token_url: token_url
      }
    end
  end
end
