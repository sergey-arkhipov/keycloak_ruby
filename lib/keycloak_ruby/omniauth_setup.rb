# frozen_string_literal: true

# lib/keycloak_ruby/omniauth.rb
require "omniauth"
require "omniauth/openid_connect"
require "keycloak_ruby"

module KeycloakRuby
  # Setup Omniauth for Keycloak
  module OmniauthSetup
    def self.setup!
      return unless defined?(Rails)

      Rails.application.config.after_initialize do
        configure_omniauth
      end
    end

    def self.configure_omniauth # rubocop:disable Metrics/MethodLength
      keycloak_config = KeycloakRuby.config
      realm_url = keycloak_config.realm_url
      config_keycloak_url = URI.parse(keycloak_config.keycloak_url)

      Rails.application.config.middleware.use OmniAuth::Builder do
        provider :openid_connect, {
          name: :keycloak,
          issuer: realm_url,
          scope: %i[openid email profile],
          response_type: :code,
          uid_field: "sub",
          client_options: {
            scheme: "http",
            host: config_keycloak_url.host,
            port: config_keycloak_url.port,
            identifier: keycloak_config.oauth_client_id,
            secret: keycloak_config.oauth_client_secret,
            redirect_uri: keycloak_config.redirect_url,
            authorization_endpoint: "#{realm_url}/protocol/openid-connect/auth",
            token_endpoint: "#{realm_url}/protocol/openid-connect/token",
            userinfo_endpoint: "#{realm_url}/protocol/openid-connect/userinfo",
            jwks_uri: "#{realm_url}/protocol/openid-connect/certs"
          }
        }
      end
    end
  end
end
