# frozen_string_literal: true

# lib/generators/keycloak_ruby/install_generator.rb
require "rails/generators"

##
# Generates the OmniAuth initializer for Keycloak integration
#
# Example:
#   rails generate keycloak_ruby:install
#
module KeycloakRuby
  ##
  # Rails generator that creates the OmniAuth initializer configuration
  # for Keycloak authentication
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../../templates", __dir__)
    desc "Creates Keycloak Ruby initializer for OmniAuth configuration"

    ##
    # Copies the OmniAuth initializer template to the Rails application
    # unless it already exists
    def copy_initializer
      if omniauth_initializer_exists?
        say_status("skipped", "OmniAuth initializer already exists at #{omniauth_initializer_path}", :yellow)
      else
        template "omniauth.rb", "config/initializers/omniauth.rb"
        say_status("created", "OmniAuth initializer at config/initializers/omniauth.rb", :green)
      end
    end

    private

    ##
    # @return [Pathname] full path to the omniauth initializer
    def omniauth_initializer_path
      @omniauth_initializer_path ||= Rails.root.join("config/initializers/omniauth.rb")
    end

    ##
    # Checks if the omniauth initializer already exists
    # @return [Boolean] true if file exists
    def omniauth_initializer_exists?
      File.exist?(omniauth_initializer_path)
    end
  end
end
