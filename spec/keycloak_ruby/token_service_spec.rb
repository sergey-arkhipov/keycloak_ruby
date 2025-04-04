# frozen_string_literal: true

require "spec_helper"

RSpec.describe KeycloakRuby::TokenService do
  let(:session) { {} }
  let(:config) { KeycloakRuby::Config.new("spec/fixtures/keycloak.yml") }
  let(:service) { described_class.new(session, config) }

  before do
    allow(User).to receive(:find_by)

    # Stub JWKS endpoint
    stub_request(:get, "http://keycloak.test/realms/test-realm/protocol/openid-connect/certs")
      .to_return(status: 200,
                 body: {
                   keys: [
                     {
                       kty: "RSA",
                       kid: "1234",
                       use: "sig",
                       n: "AQAB",
                       e: "AQAB"
                     }
                   ]
                 }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  describe "#find_user" do
    context "when user exists" do
      before do
        session[:access_token] = JWT.encode({ email: "user@example.com", exp: 10.hours.from_now.to_i }, nil, "none")
        allow(User).to receive(:find_by).with(email: "user@example.com").and_return("user-obj")
      end

      it "returns the user" do
        result = service.find_user
        expect(result).to eq("user-obj")
      end
    end

    context "when user does not exist" do
      before do
        session[:access_token] = JWT.encode({ email: "user@example.com", exp: 10.hours.from_now.to_i }, nil, "none")
        allow(User).to receive(:find_by).and_return(nil)
      end

      it "returns nil" do
        expect(service.find_user).to be_nil
      end

      it "clears tokens from session" do
        service.find_user
        expect(session).to be_empty
      end
    end
  end

  describe "#store_tokens" do
    let(:token_data) do
      {
        "token" => "access",
        "refresh_token" => "refresh",
        "id_token" => "id"
      }
    end

    before { service.store_tokens(token_data) }

    it "stores access_token" do
      expect(session[:access_token]).to eq("access")
    end

    it "stores refresh_token" do
      expect(session[:refresh_token]).to eq("refresh")
    end

    it "stores id_token" do
      expect(session[:id_token]).to eq("id")
    end
  end

  describe "#clear_tokens" do
    before do
      session[:access_token] = "abc"
      session[:refresh_token] = "xyz"
      session[:id_token] = "zzz"
      service.clear_tokens
    end

    it "clears access_token" do
      expect(session[:access_token]).to be_nil
    end

    it "clears refresh_token" do
      expect(session[:refresh_token]).to be_nil
    end

    it "clears id_token" do
      expect(session[:id_token]).to be_nil
    end
  end

  describe "#current_token" do
    context "when token is valid" do
      before do
        session[:access_token] = JWT.encode({ email: "test@example.com", exp: 1.hour.from_now.to_i }, nil, "none")
      end

      it "returns decoded claims" do
        expect(service.send(:current_token)["email"]).to eq("test@example.com")
      end
    end

    context "when token is expired" do
      let(:refresher_double) { instance_double(KeycloakRuby::TokenRefresher) }

      before do
        session[:access_token] = "expired.token"

        allow(service).to receive(:decode_token).and_wrap_original do |_original, token|
          raise KeycloakRuby::Errors::TokenExpired if token == "expired.token"

          { "email" => "refreshed@example.com" }
        end

        allow(KeycloakRuby::TokenRefresher).to receive(:new).and_return(refresher_double)
        allow(refresher_double).to receive(:call).and_return({ "access_token" => "new.token" })
      end

      it "returns refreshed claims" do
        expect(service.send(:current_token)["email"]).to eq("refreshed@example.com")
      end
    end

    context "when token is invalid" do
      before do
        session[:access_token] = "invalid.token.value"
      end

      it "returns nil" do
        expect(service.send(:current_token)).to be_nil
      end

      it "clears tokens" do
        service.send(:current_token)
        expect(session).to be_empty
      end
    end
  end

  describe "#refresh_current_token" do
    let(:refresher_double) { instance_double(KeycloakRuby::TokenRefresher) }

    before do
      session[:refresh_token] = "refresh"

      allow(KeycloakRuby::TokenRefresher).to receive(:new).and_return(refresher_double)
      allow(refresher_double).to receive(:call).and_return(
        { "access_token" => JWT.encode({ email: "refreshed@example.com", exp: 1.hour.from_now.to_i }, nil, "none") }
      )
    end

    it "returns decoded token after refresh" do
      result = service.send(:refresh_current_token)
      expect(result["email"]).to eq("refreshed@example.com")
    end
  end
end
