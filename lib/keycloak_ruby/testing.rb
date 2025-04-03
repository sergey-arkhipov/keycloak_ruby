# frozen_string_literal: true

# lib/keycloak_ruby/testing.rb
require_relative "testing/keycloak_helpers"

module KeycloakRuby
  # Include test methods
  module Testing
    def self.included(base)
      base.include KeycloakHelpers
    end
  end
end
