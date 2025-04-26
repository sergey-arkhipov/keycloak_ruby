# frozen_string_literal: true

# lib/keycloak_ruby/version.rb
module KeycloakRuby
  # The current version of the KeycloakRuby gem as a string.
  # Follows Semantic Versioning 2.0 (https://semver.org)
  # @example
  #   KeycloakRuby::VERSION # => "0.1.2"
  VERSION = "0.1.2"

  # Provides version information and comparison methods for the KeycloakRuby gem.
  # This module follows Semantic Versioning 2.0 guidelines.
  #
  # @example Getting version information
  #   KeycloakRuby::Version.to_a    # => [0, 1, 1]
  #   KeycloakRuby::Version.to_h    # => { major: 0, minor: 1, patch: 1 }
  #   KeycloakRuby::Version.to_s    # => "0.1.1"
  #
  # @example Version comparison
  #   KeycloakRuby::Version >= '0.1.0'  # => true
  #   KeycloakRuby::Version >= '1.0.0'  # => false
  module Version
    # Returns the version components as an array of integers
    # @return [Array<Integer>] the version components [major, minor, patch]
    # @example
    #   KeycloakRuby::Version.to_a # => [0, 1, 1]
    def self.to_a
      VERSION.split(".").map(&:to_i)
    end

    # Returns the version components as a hash with symbols
    # @return [Hash<Symbol, Integer>] the version components {major:, minor:, patch:}
    # @example
    #   KeycloakRuby::Version.to_h # => { major: 0, minor: 1, patch: 1 }
    def self.to_h
      { major: to_a[0], minor: to_a[1], patch: to_a[2] }
    end

    # Compares the current version with another version string
    # @param version_string [String] the version to compare with (e.g. "1.2.3")
    # @return [Boolean] true if current version is greater or equal
    # @example
    #   KeycloakRuby::Version >= '0.1.0' # => true
    def self.>=(version_string)
      Gem::Version.new(VERSION) >= Gem::Version.new(version_string)
    end

    # Returns the version string
    # @return [String] the version string
    # @example
    #   KeycloakRuby::Version.to_s # => "0.1.1"
    def self.to_s
      VERSION
    end
  end
end
