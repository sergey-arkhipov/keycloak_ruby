# frozen_string_literal: true

require "spec_helper"

RSpec.describe KeycloakRuby::ResponseValidator do
  subject(:validator) { described_class.new(response) }

  let(:headers) { { "Content-Type" => "application/json" } }

  describe "#validate" do
    context "when response is valid and includes access_token" do
      let(:response) { instance_double(HTTParty::Response, body: '{"access_token":"abc"}', success?: true) }

      it "returns true" do
        expect(validator.validate).to be true
      end
    end

    context "when response is unsuccessful (status != 2xx)" do
      let(:response) { instance_double(HTTParty::Response, body: '{"access_token":"abc"}', success?: false) }

      it "returns false" do
        expect(validator.validate).to be false
      end
    end

    context "when response contains error key" do
      let(:response) { instance_double(HTTParty::Response, body: '{"error":"server_error"}', success?: true) }

      it "returns false" do
        expect(validator.validate).to be false
      end
    end

    context "when response has invalid_grant error" do
      let(:response) { instance_double(HTTParty::Response, body: '{"error":"invalid_grant"}', success?: true) }

      it "returns false" do
        expect(validator.validate).to be false
      end
    end

    context "when access_token is missing" do
      let(:response) { instance_double(HTTParty::Response, body: '{"token_type":"Bearer"}', success?: true) }

      it "returns false" do
        expect(validator.validate).to be false
      end
    end

    context "when response is not JSON" do
      let(:response) { instance_double(HTTParty::Response, body: "<html>not json</html>", success?: true) }

      it "returns false" do
        expect(validator.validate).to be false
      end
    end
  end

  describe "#validate!" do
    context "when response is valid" do
      let(:response) { instance_double(HTTParty::Response, body: '{"access_token":"abc"}', success?: true) }

      it "returns parsed data" do
        expect(validator.validate!).to include("access_token" => "abc")
      end
    end

    context "when response has invalid_grant" do
      let(:response) do
        instance_double(HTTParty::Response,
                        body: '{"error":"invalid_grant","error_description":"token expired"}',
                        success?: true)
      end

      it "raises TokenRefreshFailed with message about invalid grant" do
        expect do
          validator.validate!
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /Invalid grant: token expired/)
      end
    end

    context "when response has generic error" do
      let(:response) do
        instance_double(HTTParty::Response,
                        body: '{"error":"unauthorized_client","error_description":"client not allowed"}',
                        success?: true)
      end

      it "raises TokenRefreshFailed with message about keycloak error" do
        expect do
          validator.validate!
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed,
                           /Keycloak error: unauthorized_client - client not allowed/)
      end
    end

    context "when access_token is missing" do
      let(:response) { instance_double(HTTParty::Response, body: '{"token_type":"Bearer"}', success?: true) }

      it "raises TokenRefreshFailed with message about missing token" do
        expect do
          validator.validate!
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /access token missing/)
      end
    end

    context "when response failed with 500" do
      let(:response) do
        instance_double(HTTParty::Response, code: 500, body: '{"error":"server_error"}', success?: false)
      end

      it "raises TokenRefreshFailed with status and error" do
        expect do
          validator.validate!
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /Keycloak API request failed with status 500/)
      end
    end

    context "when response body is not JSON" do
      let(:response) { instance_double(HTTParty::Response, code: 500, body: "Internal Server Error", success?: false) }

      it "raises TokenRefreshFailed with raw body message" do
        expect do
          validator.validate!
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /Internal Server Error/)
      end
    end

    context "when response body is large non-json" do
      let(:response) { instance_double(HTTParty::Response, code: 500, body: "A" * 1000, success?: false) }

      it "raises TokenRefreshFailed with message pointing to full body" do
        expect do
          validator.validate!
        end.to raise_error(KeycloakRuby::Errors::TokenRefreshFailed, /See response body for details/)
      end
    end
  end
end
