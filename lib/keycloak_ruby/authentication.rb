# frozen_string_literal: true

# lib/keycloak_ruby/authentication.rb
require "active_support/concern"
module KeycloakRuby
  # Concern to add methods to ApplicationController
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!
    end

    def keycloak_jwt_service
      @keycloak_jwt_service ||= KeycloakRuby::TokenService.new(session)
    end

    def authenticate_user!
      redirect_to login_path unless current_user&.active?
    end

    def current_user
      @current_user ||= keycloak_jwt_service.find_user
    end
  end
end
