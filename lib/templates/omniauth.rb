# frozen_string_literal: true

# lib/templates/omniauth.rb
require "keycloak_ruby"

realm_url = KeycloakRuby.config.realm_url
keycloak_url = URI.parse(KeycloakRuby.config.keycloak_url)
keycloak_config = KeycloakRuby.config
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect, {
    name: :keycloak,
    issuer: realm_url,
    scope: %i[openid email profile],
    response_type: :code,
    uid_field: "sub",
    client_options: {
      scheme: "http",
      host: keycloak_url.host,
      port: keycloak_url.port,
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
