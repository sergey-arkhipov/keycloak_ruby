# frozen_string_literal: true

# lib/keycloak_ruby/authentication.rb
module KeycloakRuby
  # Concern to add methods to ApplicationController
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :keycloak_authenticate_user!
      before_action :keycloak_set_current_user
    end

    def keycloak_jwt_service
      @keycloak_jwt_service ||= KeycloakRuby::TokenService.new(session)
    end

    def keycloak_authenticate_user!
      redirect_to login_path unless keycloak_current_user&.active?
    end

    def keycloak_current_user
      @keycloak_current_user ||= keycloak_jwt_service.find_user
    end

    def keycloak_set_current_user
      Current.user = keycloak_current_user
    end
  end
end
