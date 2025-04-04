# frozen_string_literal: true

require "keycloak_ruby"
require "debug"
require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true)

unless defined?(Rails)
  module Rails
    def self.env
      @env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || "test")
    end

    def self.cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end

    # Only define Application if needed for other tests
    class Application
      def env
        Rails.env
      end
    end
  end
end

class ::User
  def self.find_by(email:)
    nil
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
