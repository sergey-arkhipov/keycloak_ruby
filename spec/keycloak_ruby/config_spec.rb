# frozen_string_literal: true

# spec/keycloak_ruby/config_spec.rb
require "spec_helper"

RSpec.describe KeycloakRuby::Config do
  subject(:keycloak_config) { described_class.new(fixture_path) }

  let(:fixture_path) { "spec/fixtures/keycloak.yml" }
  let(:test_config) { YAML.load_file(fixture_path)["test"] }

  describe "initialization" do
    context "with fixture file" do
      before { ENV["APP_ENV"] = "test" } # Explicitly set test environment

      it "loads keycloak_url from YAML" do
        expect(keycloak_config.keycloak_url).to eq(test_config["keycloak_url"])
      end

      it "loads realm from YAML" do
        expect(keycloak_config.realm).to eq(test_config["realm"])
      end

      it "loads oauth_client_id from YAML" do
        expect(keycloak_config.oauth_client_id).to eq(test_config["oauth_client_id"])
      end

      it "loads admin_client_id from YAML" do
        expect(keycloak_config.admin_client_id).to eq(test_config["admin_client_id"])
      end

      it "loads admin_client_secret from YAML" do
        expect(keycloak_config.admin_client_secret).to eq(test_config["admin_client_secret"])
      end
    end

    context "with default config path" do
      subject(:default_config) { described_class.new }

      it "uses DEFAULT_CONFIG_PATH when no path provided" do
        expect(default_config.config_path).to eq(described_class::DEFAULT_CONFIG_PATH)
      end
    end
  end

  describe "URL generation" do
    before { ENV["APP_ENV"] = "test" } # Explicitly set test environment

    it "generates correct realm_url" do
      expected = "#{test_config["keycloak_url"]}/realms/#{test_config["realm"]}"
      expect(keycloak_config.realm_url).to eq(expected)
    end

    it "generates correct redirect_url" do
      expected = "#{test_config["app_host"]}/auth/keycloak/callback"
      expect(keycloak_config.redirect_url).to eq(expected)
    end

    it "generates correct logout_url" do
      expected = "#{test_config["keycloak_url"]}/realms/#{test_config["realm"]}/protocol/openid-connect/logout"
      expect(keycloak_config.logout_url).to eq(expected)
    end

    it "generates correct token_url" do
      expected = "#{test_config["keycloak_url"]}/realms/#{test_config["realm"]}/protocol/openid-connect/token"
      expect(keycloak_config.token_url).to eq(expected)
    end
  end

  describe "validation" do
    let(:valid_config) { described_class.new(fixture_path) }

    it "raises error when keycloak_url is missing" do
      valid_config.keycloak_url = nil
      expect { valid_config.validate! }.to raise_error(KeycloakRuby::Errors::ConfigurationError, /keycloak_url/)
    end

    it "raises error when realm is missing" do
      valid_config.realm = nil
      expect { valid_config.validate! }.to raise_error(KeycloakRuby::Errors::ConfigurationError, /realm/)
    end

    it "raises error when oauth_client_id is missing" do
      valid_config.oauth_client_id = nil
      expect { valid_config.validate! }.to raise_error(KeycloakRuby::Errors::ConfigurationError, /oauth_client_id/)
    end

    it "does not raise when all required attributes are present" do
      expect { valid_config.validate! }.not_to raise_error
    end
  end

  describe "environment handling" do
    before { ENV["APP_ENV"] = nil }

    context "when in Rails context" do
      let(:rails_env) { ActiveSupport::StringInquirer.new("production") }

      before do
        # Define minimal Rails structure if not present
        unless defined?(Rails)
          stub_const("Rails", Module.new do
            def self.env
              @env ||= ActiveSupport::StringInquirer.new("test")
            end
          end)
        end

        # Mock the Rails.env to return our desired environment
        allow(Rails).to receive(:env).and_return(rails_env)
      end

      it "uses Rails.env" do
        config = described_class.new(fixture_path)
        expect(config.send(:current_env)).to eq("production")
      end
    end

    context "without Rails" do
      before { hide_const("Rails") if defined?(Rails) }

      it "uses APP_ENV when set" do
        ENV["APP_ENV"] = "staging"
        config = described_class.new(fixture_path)
        expect(config.send(:current_env)).to eq("staging")
      end

      it "defaults to development when no environment specified" do
        config = described_class.new(fixture_path)
        expect(config.send(:current_env)).to eq("development")
      end
    end
  end
end
