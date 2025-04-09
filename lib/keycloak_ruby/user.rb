# frozen_string_literal: true

# lib/keycloak_ruby/user.rb
module KeycloakRuby
  # User-related operations for interacting with Keycloak.
  # This class provides a simple interface for creating, deleting, and finding users in Keycloak.
  class User
    class << self
      # Creates a new user in Keycloak.
      #
      # @param user_attrs [Hash] A hash of user attributes (e.g., :username, :email, :password, :temporary).
      # @return [Hash] The created user's data.
      # @raise [KeycloakRuby::Error] If the user creation fails.
      def create(user_attrs = {})
        client.create_user(user_attrs)
      end

      # Deletes users from Keycloak based on a search string.
      #
      # @param search_string [String] A string to search for users (e.g., username, email, etc.).
      # @return [void]
      # @raise [KeycloakRuby::Error] If any user deletion fails.
      def delete(search_string)
        client.delete_users(search_string)
      end

      # Deletes a user from Keycloak by ID.
      #
      # @param user_id [String] The ID of the user to delete.
      # @return [void]
      # @raise [KeycloakRuby::Error] If the deletion fails.
      def delete_by_id(user_id)
        client.delete_user_by_id(user_id)
      end

      # Finds users in Keycloak based on a search string.
      #
      # @param search_string [String] A string to search for users (e.g., username, email, etc.).
      # @return [Array<Hash>] An array of user objects (hashes) matching the search criteria.
      # @raise [KeycloakRuby::Error] If the search fails.
      def find(search_string)
        client.find_users(search_string)
      end

      # Finds a Keycloak user by email.
      # If no user is found, creates a new user in Keycloak with the given attributes.
      #
      # @param user_attrs [Hash] A hash of user attributes. Must include:
      #   :username [String] - the username for the user
      #   :email [String] - the user's email address
      #   :password [String] - the user's initial password
      #   :temporary [Boolean] (optional) - whether the password should be temporary (default: true)
      #
      # @return [Hash] Result hash containing:
      #   :user_data [Hash] - Keycloak user data (either found or newly created)
      #   :created [Boolean] - true if the user was created, false if already existed
      #
      # @raise [KeycloakRuby::Errors::Error] if any request to Keycloak fails
      def find_or_create(user_attrs = {})
        user = find(user_attrs[:email]).find do |u|
          u["email"].casecmp(user_attrs[:email]).zero?
        end

        if user
          { user_data: user, created: false }
        else
          created_user = create(user_attrs)
          { user_data: created_user, created: true }
        end
      end

      private

      # Provides a singleton instance of the KeycloakRuby::Client.
      #
      # @return [KeycloakRuby::Client] The client instance used for making API requests.
      def client
        @client ||= KeycloakRuby::Client.new
      end
    end
  end
end
