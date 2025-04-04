# frozen_string_literal: true

require "spec_helper"

RSpec.describe KeycloakRuby::RequestPerformer do
  subject(:performer) { described_class.new(KeycloakRuby::Config.new("spec/fixtures/keycloak.yml")) }

  let(:url) { "http://keycloak.test/fake" }
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:body) { '{"foo":"bar"}' }
  let(:params) do
    KeycloakRuby::RequestParams.new(
      http_method: :post,
      url: url,
      headers: headers,
      body: body,
      success_codes: [200],
      error_class: KeycloakRuby::Errors::APIError,
      error_message: "Request failed"
    )
  end

  describe "#call" do
    context "when request is successful" do
      let(:response) { performer.call(params) }

      before do
        stub_request(:post, url)
          .with(headers: headers, body: body)
          .to_return(status: 200, body: '{"ok":true}', headers: { "Content-Type" => "application/json" })
      end

      it "returns response with status 200" do
        expect(response.code).to eq(200)
      end

      it "returns response with 'ok' in body" do
        expect(response.body).to include("ok")
      end
    end

    context "when response status is not in success_codes" do
      before do
        stub_request(:post, url).to_return(status: 403, body: "Forbidden")
      end

      it "raises the specified error class" do
        expect do
          performer.call(params)
        end.to raise_error(KeycloakRuby::Errors::APIError, /Request failed: 403/)
      end
    end

    context "when success_codes is a range" do
      let(:params_with_range) { params.dup.tap { |p| p.success_codes = 200..299 } }

      before do
        stub_request(:post, url).to_return(status: 201, body: '{"created":true}')
      end

      it "accepts the response within the range" do
        response = performer.call(params_with_range)
        expect(response.code).to eq(201)
      end
    end

    context "when HTTParty raises an error" do
      let(:logger_spy) { instance_spy(Logger) }

      before do
        KeycloakRuby.logger = logger_spy
        allow(HTTParty).to receive(:post).and_raise(HTTParty::Error.new("Connection failed"))
      end

      it "logs an HTTP error" do
        begin
          performer.call(params)
        rescue KeycloakRuby::Errors::APIError
          # Swallow the error — we're testing logging only
        end

        expect(logger_spy).to have_received(:error).with(/Request failed \(HTTParty error\): Connection failed/)
      end

      it "raises APIError on HTTP error" do
        expect do
          performer.call(params)
        end.to raise_error(KeycloakRuby::Errors::APIError, /Connection failed/)
      end
    end
  end
end
