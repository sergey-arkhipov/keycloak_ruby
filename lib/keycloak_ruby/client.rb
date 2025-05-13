# frozen_string_literal: true

# lib/keycloak_ruby/client.rb
module KeycloakRuby
  # Client for interacting with Keycloak (create, delete, and find users, etc.).
  # rubocop:disable Metrics/ClassLength
  # rubocop:disable Metrics/MethodLength
  # :reek:TooManyMethods
  class Client
    def initialize(config = KeycloakRuby.config)
      @config = config
      @request_performer = RequestPerformer.new(@config)
    end

    # Authenticates a user with Keycloak and returns token data upon success.
    #
    # @param username [String] The user's username or email.
    # @param password [String] The user's password.
    # @return [Hash] The token data (access_token, refresh_token, id_token, etc.).
    # @raise [KeycloakRuby::Errors::InvalidCredentials] If authentication fails.
    def authenticate_user(username:, password:)
      body = build_auth_body(username, password)
      response = http_request(
        http_method: :post,
        url: @config.token_url,
        body: URI.encode_www_form(body),
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        success_codes: [200],
        error_class: KeycloakRuby::Errors::InvalidCredentials,
        error_message: "Failed to authenticate with Keycloak"
      )
      response.parsed_response
    end

    # Creates a user in Keycloak and returns the newly created user's data.
    #
    # @param user_attrs [Hash] A hash of user attributes. Must contain:
    #   :username, :email, :password, :temporary
    # @option user_attrs [String] :username The username for the new user.
    # @option user_attrs [String] :email The user's email.
    # @option user_attrs [String] :password The initial password.
    # @option user_attrs [Boolean] :temporary Whether to force a password update on first login.
    #
    # @raise [KeycloakRuby::Errors::UserCreationError] If user creation fails.
    # @return [Hash] The newly created user's data.
    def create_user(user_attrs = {})
      user_data = self.class.build_user_data(user_attrs)

      response = http_request(
        http_method: :post,
        url: "#{@config.keycloak_url}/admin/realms/#{@config.realm}/users",
        headers: default_headers,
        body: user_data.to_json,
        success_codes: [201],
        error_class: KeycloakRuby::Errors::UserCreationError,
        error_message: "Failed to create Keycloak user"
      )

      # Extract user ID from the "Location" header, then fetch user details
      user_id = response.headers["Location"].split("/").last
      fetch_user(user_id)
    end

    # Deletes all users that match the provided search string (e.g., username, email).
    #
    # @param search_string [String] The search criteria for finding users in Keycloak.
    # @raise [KeycloakRuby::Errors::UserDeletionError] If any user deletion fails.
    def delete_users(search_string)
      user_ids = find_users(search_string).pluck("id")
      user_ids.each { |id| delete_user_by_id(id) }
    end

    # Deletes a single user by ID in Keycloak.
    #
    # @param user_id [String] The ID of the user to delete.
    # @raise [KeycloakRuby::Errors::UserDeletionError] If the deletion fails.
    def delete_user_by_id(user_id)
      http_request(
        http_method: :delete,
        url: "#{@config.keycloak_url}/admin/realms/#{@config.realm}/users/#{user_id}",
        headers: default_headers,
        success_codes: [204],
        error_class: KeycloakRuby::Errors::UserDeletionError,
        error_message: "Failed to delete Keycloak user with ID #{user_id}"
      )
    end

    # Finds all users in Keycloak that match the given search string.
    #
    # @param search [String] The search query (e.g., part of username or email).
    # @return [Array<Hash>] An array of user objects.
    # @raise [KeycloakRuby::Errors::APIError] If the request fails.
    def find_users(search)
      response = http_request(
        http_method: :get,
        url: "#{@config.keycloak_url}/admin/realms/#{@config.realm}/users/?search=#{search}",
        headers: default_headers,
        success_codes: [200],
        error_class: KeycloakRuby::Errors::APIError,
        error_message: "Failed to get Keycloak users"
      )
      JSON.parse(response.body)
    end

    # Updates the redirect URIs for a specific client in Keycloak.
    #
    # @param client_id [String] The client ID in Keycloak.
    # @param redirect_uris [Array<String>] A list of valid redirect URIs for this client.
    # @raise [KeycloakRuby::Errors::ConnectionError] If the update request fails.
    def update_client_redirect_uris(client_id:, redirect_uris:)
      client_record = find_client_by_id(client_id)
      update_redirect_uris_for(client_record["id"], redirect_uris)
    end

    def self.build_user_data(attrs)
      { username: attrs.fetch(:username), email: attrs.fetch(:email), enabled: true,
        credentials: [
          {
            type: "password",
            value: attrs.fetch(:password),
            temporary: attrs.fetch(:temporary, true)
          }
        ] }
    end

    def self.build_request_params(opts)
      RequestParams.new(
        http_method: opts.fetch(:http_method),
        url: opts.fetch(:url),
        headers: opts.fetch(:headers, {}),
        body: opts.fetch(:body, nil),
        success_codes: opts.fetch(:success_codes, [200]),
        error_class: opts.fetch(:error_class, KeycloakRuby::Errors::APIError),
        error_message: opts.fetch(:error_message, "Request failed")
      )
    end

    private

    def build_auth_body(username, password)
      {
        client_id: @config.oauth_client_id,
        client_secret: @config.oauth_client_secret,
        username: username,
        password: password,
        grant_type: "password"
      }
    end

    # Builds RequestParams and passes them to the RequestPerformer.
    def http_request(options = {})
      params = self.class.build_request_params(options)
      @request_performer.call(params)
    end

    # Retrieves client details by its "clientId".
    #
    # @param client_id [String] The "clientId" in Keycloak.
    # @return [Hash] The client details.
    # @raise [KeycloakRuby::Errors::ClientError] If no matching client is found or the request fails.
    def find_client_by_id(client_id)
      response = http_request(
        http_method: :get,
        url: "#{@config.keycloak_url}/admin/realms/#{@config.realm}/clients",
        headers: default_headers,
        success_codes: [200],
        error_class: KeycloakRuby::Errors::ClientError,
        error_message: "Failed to fetch clients"
      )

      clients = JSON.parse(response.body)
      client_record = clients.find { |client| client["clientId"] == client_id }
      raise KeycloakRuby::Errors::ClientError, "Client #{client_id} not found" unless client_record

      client_record
    end

    # Performs a PUT request to update the redirect URIs for a given client in Keycloak.
    #
    # @param client_id [String] The internal Keycloak client ID.
    # @param redirect_uris [Array<String>] List of valid redirect URIs for this client.
    # @raise [KeycloakRuby::Errors::ConnectionError] If the update request fails.
    def update_redirect_uris_for(client_id, redirect_uris)
      http_request(
        http_method: :put,
        url: "#{@config.keycloak_url}/admin/realms/#{@config.realm}/clients/#{client_id}",
        headers: default_headers,
        body: { redirectUris: redirect_uris }.to_json,
        success_codes: (200..299),
        error_class: KeycloakRuby::Errors::ConnectionError,
        error_message: "Failed to update redirectUris for client #{client_id}"
      )
    end

    # Fetches a user by ID from Keycloak.
    #
    # @param user_id [String] The user's ID in Keycloak.
    # @return [Hash] The Keycloak user data.
    # @raise [KeycloakRuby::Errors::UserNotFound] If the user cannot be found or the request fails.
    def fetch_user(user_id)
      response = http_request(
        http_method: :get,
        url: "#{@config.keycloak_url}/admin/realms/#{@config.realm}/users/#{user_id}",
        headers: default_headers,
        success_codes: [200],
        error_class: KeycloakRuby::Errors::UserNotFound,
        error_message: "Failed to fetch Keycloak user with ID #{user_id}"
      )

      response.parsed_response
    end

    # Retrieves the admin token used to authenticate calls to the Keycloak Admin API.
    #
    # @return [String] The admin access token.
    # @raise [KeycloakRuby::Errors::TokenVerificationFailed] If the token request fails.
    def admin_token
      body = {
        client_id: @config.admin_client_id,
        client_secret: @config.admin_client_secret,
        grant_type: "client_credentials"
      }

      response = http_request(
        http_method: :post,
        url: "#{@config.keycloak_url}/realms/#{@config.realm}/protocol/openid-connect/token",
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: URI.encode_www_form(body),
        success_codes: [200],
        error_class: KeycloakRuby::Errors::TokenVerificationFailed,
        error_message: "Failed to get Keycloak admin token"
      )

      response.parsed_response["access_token"]
    end

    # Returns a set of default headers for requests requiring the admin token.
    #
    # @return [Hash] A headers Hash including Authorization and Content-Type.
    def default_headers
      {
        "Authorization" => "Bearer #{admin_token}",
        "Content-Type" => "application/json"
      }
    end
  end
  # rubocop:enable Metrics/ClassLength
  # rubocop:enable Metrics/MethodLength
end
