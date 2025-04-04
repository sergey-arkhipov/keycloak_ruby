# frozen_string_literal: true

# spec/keycloak_ruby/client_spec.rb
require "spec_helper"

RSpec.describe KeycloakRuby::Client do
  subject(:client) { described_class.new(keycloak_config) }

  let(:keycloak_config) { KeycloakRuby::Config.new("spec/fixtures/keycloak.yml") }

  before do
    stub_request(:post, "http://keycloak.test/realms/test-realm/protocol/openid-connect/token")
      .with(
        body: URI.encode_www_form(
          client_id: "admin-cli",
          client_secret: "admin-secret",
          grant_type: "client_credentials"
        )
      )
      .to_return(
        status: 200,
        body: '{"access_token":"admin-token"}',
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe "#authenticate_user" do
    context "when credentials are valid" do
      before do
        stub_request(:post, "http://keycloak.test/realms/test-realm/protocol/openid-connect/token")
          .with(body: /grant_type=password/)
          .to_return(
            status: 200,
            body: '{"access_token":"user-access-111","refresh_token":"refresh-222"}',
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns parsed token data" do
        tokens = client.authenticate_user(username: "alice", password: "secret")
        expect(tokens).to include("access_token" => "user-access-111", "refresh_token" => "refresh-222")
      end
    end

    context "when credentials are invalid" do
      before do
        stub_request(:post, "http://keycloak.test/realms/test-realm/protocol/openid-connect/token")
          .with(body: /grant_type=password/)
          .to_return(
            status: 401,
            body: '{"error":"invalid_grant"}',
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises InvalidCredentials" do
        expect do
          client.authenticate_user(username: "alice", password: "wrong")
        end.to raise_error(KeycloakRuby::Errors::InvalidCredentials, /Failed to authenticate with Keycloak/)
      end
    end
  end

  describe "#create_user" do
    let(:user_attrs) do
      {
        username: "testuser",
        email: "test@example.com",
        password: "pwd123",
        temporary: false
      }
    end

    context "when Keycloak returns 201 Created" do
      before do
        # 1) POST => Location = .../users/NEW-ID
        stub_request(:post, "http://keycloak.test/admin/realms/test-realm/users")
          .to_return(
            status: 201,
            headers: { "Location" => "http://keycloak.test/admin/realms/test-realm/users/NEW-ID" }
          )

        # 2) GET => {"id":"NEW-ID",...}
        stub_request(:get, "http://keycloak.test/admin/realms/test-realm/users/NEW-ID")
          .to_return(
            status: 200,
            body: '{"id":"NEW-ID","username":"testuser"}',
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the created user data" do
        created_user = client.create_user(user_attrs)
        expect(created_user).to eq(
          "id" => "NEW-ID",
          "username" => "testuser"
        )
      end
    end

    context "when Keycloak returns an error" do
      before do
        stub_request(:post, "http://keycloak.test/admin/realms/test-realm/users")
          .to_return(
            status: 400,
            body: '{"error":"some-bad-request"}'
          )
      end

      it "raises UserCreationError" do
        expect do
          client.create_user(user_attrs)
        end.to raise_error(KeycloakRuby::Errors::UserCreationError, /Failed to create Keycloak user/)
      end
    end
  end

  describe "#delete_users" do
    before do
      stub_request(:get, "http://keycloak.test/admin/realms/test-realm/users/?search=some-search")
        .to_return(
          status: 200,
          body: '[{"id":"u1"},{"id":"u2"}]',
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:delete, "http://keycloak.test/admin/realms/test-realm/users/u1").to_return(status: 204)
      stub_request(:delete, "http://keycloak.test/admin/realms/test-realm/users/u2").to_return(status: 204)
      client.delete_users("some-search")
    end

    it "deletes user u1" do
      expect(a_request(:delete, "http://keycloak.test/admin/realms/test-realm/users/u1")).to have_been_made.once
    end

    it "deletes user u2" do
      expect(a_request(:delete, "http://keycloak.test/admin/realms/test-realm/users/u2")).to have_been_made.once
    end
  end

  describe "#delete_user_by_id" do
    context "when user deletion succeeds (204)" do
      before do
        stub_request(:delete, "http://keycloak.test/admin/realms/test-realm/users/123")
          .to_return(status: 204)
      end

      it "does not raise error" do
        expect { client.delete_user_by_id("123") }.not_to raise_error
      end
    end

    context "when user not found (404)" do
      before do
        stub_request(:delete, "http://keycloak.test/admin/realms/test-realm/users/123")
          .to_return(status: 404, body: "User not found")
      end

      it "raises UserDeletionError" do
        expect do
          client.delete_user_by_id("123")
        end.to raise_error(KeycloakRuby::Errors::UserDeletionError, /Failed to delete Keycloak user/)
      end
    end
  end

  describe "#find_users" do
    before do
      stub_request(:get, %r{http://keycloak\.test/admin/realms/test-realm/users/\?search=})
        .to_return(
          status: 200,
          body: '[{"id":"u1"}]',
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns parsed array of users" do
      result = client.find_users("test")
      expect(result).to eq([{ "id" => "u1" }])
    end
  end

  describe "#update_client_redirect_uris" do
    context "when client exists" do
      before do
        # 1) GET /clients => [{"clientId":"myclient","id":"internal-999"}]
        stub_request(:get, "http://keycloak.test/admin/realms/test-realm/clients")
          .to_return(
            status: 200,
            body: '[{"clientId":"myclient","id":"internal-999"}]',
            headers: { "Content-Type" => "application/json" }
          )

        # 2) PUT /clients/internal-999 => 204 No Content
        stub_request(:put, "http://keycloak.test/admin/realms/test-realm/clients/internal-999")
          .with(body: { redirectUris: ["http://foo/callback"] }.to_json)
          .to_return(status: 204)
      end

      it "updates the client redirect uris" do
        expect do
          client.update_client_redirect_uris(client_id: "myclient", redirect_uris: ["http://foo/callback"])
        end.not_to raise_error
      end
    end

    context "when client not found" do
      before do
        stub_request(:get, "http://keycloak.test/admin/realms/test-realm/clients")
          .to_return(status: 200, body: '[{"clientId":"another","id":"some-other"}]')
      end

      it "raises ClientError" do
        expect do
          client.update_client_redirect_uris(client_id: "myclient", redirect_uris: [])
        end.to raise_error(KeycloakRuby::Errors::ClientError, /Client myclient not found/)
      end
    end
  end
end
