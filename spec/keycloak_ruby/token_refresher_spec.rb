# frozen_string_literal: true

require "spec_helper"

RSpec.describe KeycloakRuby::TokenRefresher do
  subject(:refresher) { described_class.new(session, config) }

  let(:session) { { refresh_token: "valid-refresh-token" } }
  let(:config) { KeycloakRuby::Config.new("spec/fixtures/keycloak.yml") }

  describe "#call" do
    context "when refresh is successful" do
      let(:result) { refresher.call }

      before do
        stub_request(:post, config.token_url)
          .to_return(
            status: 200,
            body: {
              access_token: "new-access-token",
              refresh_token: "new-refresh-token"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns new access_token" do
        expect(result["access_token"]).to eq("new-access-token")
      end

      it "returns new refresh_token" do
        expect(result["refresh_token"]).to eq("new-refresh-token")
      end
    end

    context "when response contains error (e.g., invalid_grant)" do
      before do
        stub_request(:post, config.token_url)
          .to_return(
            status: 401,
            body: { error: "invalid_grant", error_description: "Refresh token expired" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises TokenRefreshFailed" do
        expect do
          refresher.call
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /invalid_grant/)
      end
    end

    context "when HTTParty raises an error" do
      before do
        allow(HTTParty).to receive(:post).and_raise(HTTParty::Error.new("Connection failed"))
      end

      it "raises TokenRefreshFailed" do
        expect do
          refresher.call
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /Connection failed/)
      end
    end

    context "when response does not contain access_token" do
      before do
        stub_request(:post, config.token_url)
          .to_return(
            status: 200,
            body: { foo: "bar" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises TokenRefreshFailed when access_token is missing" do
        expect do
          refresher.call
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /Token refresh failed\. Status: 200/)
      end
    end
  end
end
