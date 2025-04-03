# frozen_string_literal: true

# lib/keycloak_ruby/request_params.rb
module KeycloakRuby
  # A small, typed struct for request parameters
  RequestParams = Struct.new(
    :http_method,
    :url,
    :headers,
    :body,
    :success_codes,
    :error_class,
    :error_message,
    keyword_init: true
  )
end
