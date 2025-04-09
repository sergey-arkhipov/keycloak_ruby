# frozen_string_literal: true

# lib/keycloak_ruby/version.rb
# Module for interacting with Keycloak
module KeycloakRuby
  # Version module following Semantic Versioning 2.0 guidelines
  # Provides detailed version information and helper methods
  #
  # @example Getting version information
  #   KeycloakRuby::Version::VERSION      # => "0.1.0"
  #   KeycloakRuby::Version.to_a          # => [0, 1, 0]
  #   KeycloakRuby::Version.to_h          # => { major: 0, minor: 1, patch: 0, pre: nil }
  #   KeycloakRuby.version                # => "0.1.0"
  #
  # @example Checking version
  #   KeycloakRuby::Version >= '0.1.0'    # => true
  # Module for work with Version
  module Version
    # Major version number (incompatible API changes)
    MAJOR = 0
    # Minor version number (backwards-compatible functionality)
    MINOR = 1
    # Patch version number (backwards-compatible bug fixes)
    PATCH = 1
    # Pre-release version (nil for stable releases)
    PRE = nil

    # Full version string
    VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join(".").freeze

    # Returns version components as an array
    # @return [Array<Integer, Integer, Integer, String|nil>]
    def self.to_a
      [MAJOR, MINOR, PATCH, PRE]
    end

    # Returns version components as a hash
    # @return [Hash<Symbol, Integer|String|nil>]
    def self.to_h
      { major: MAJOR, minor: MINOR, patch: PATCH, pre: PRE }
    end

    # Compares version with another version string
    # @param version_string [String] version to compare with (e.g., "1.2.3")
    # @return [Boolean]
    def self.>=(version_string)
      Gem::Version.new(VERSION) >= Gem::Version.new(version_string)
    end

    # Returns the full version string
    # @return [String]
    def self.to_s
      VERSION
    end
  end

  # Returns the current gem version
  # @return [String]
  def self.version
    Version::VERSION
  end
end
