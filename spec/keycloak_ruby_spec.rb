# frozen_string_literal: true

require "spec_helper"

RSpec.describe KeycloakRuby do
  subject(:keycloak) { described_class } # Именованный subject для модуля

  let(:expected_constants) do
    %w[
      Authentication
      Client
      Config
      Errors
      RequestParams
      RequestPerformer
      ResponseValidator
      TokenRefresher
      TokenService
      User
      Version
    ]
  end

  let(:loader) do
    Zeitwerk::Loader.for_gem(warn_on_extra_files: false).tap do |l|
      l.ignore("#{__dir__}/")
      l.enable_reloading
      l.setup
      begin
        l.push_dir("./lib")
      rescue Zeitwerk::Error
        # Ignore already managed directory error
      end
      l.reload
    end
  end

  it "has a version number" do
    expect(KeycloakRuby::VERSION).not_to be_nil
  end

  it "loads all expected constants via Zeitwerk" do
    loader # Initialize loader
    loaded = described_class.constants
                            .map(&:to_s)
                            .reject { |c| %w[VERSION Testing].include?(c) }

    expect(loaded).to match_array(expected_constants)
  end

  describe "#logger" do
    before do
      keycloak.instance_variable_set(:@logger, nil) # Сбрасываем мемоизацию
    end

    it "returns Rails.logger when available" do
      rails_logger = Logger.new($stdout)
      allow(Rails).to receive(:logger).and_return(rails_logger)
      expect(keycloak.logger).to eq(rails_logger)
    end

    it "creates a default logger when Rails is not defined" do
      hide_const("Rails") # Удаляем константу Rails
      expect(keycloak.logger).to be_a(Logger)
    end

    it "sets default logger level to INFO when Rails is not defined" do
      hide_const("Rails") # Удаляем константу Rails
      expect(keycloak.logger.level).to eq(Logger::INFO)
    end
  end
end
