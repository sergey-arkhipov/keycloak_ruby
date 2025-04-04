# frozen_string_literal: true

require File.expand_path("lib/keycloak_ruby/version", __dir__)
Gem::Specification.new do |spec|
  spec.name        = "keycloak_ruby"
  spec.version     = KeycloakRuby::Version
  spec.summary     = "Keycloak authentication solution for Rails"
  spec.description = "Library for using keycloak authentication with Rails"
  spec.authors     = ["Sergey Arkhipov", "Georgy Shcherbakov"]
  spec.email       = %w[sergey-arkhipov@ya.ru lordsynergymail@gmail.com]
  spec.homepage    = "https://github.com/sergey-arkhipov/keycloak_ruby"
  spec.license = "GPL"
  spec.required_ruby_version = ">= 3.4"
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.require_paths = ["lib"]
  spec.add_dependency "httparty"
  spec.add_dependency "jwt"
  spec.add_dependency "omniauth"
  spec.add_dependency "omniauth_openid_connect"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata = {
    "homepage_uri" => "https://github.com/sergey-arkhipov/keycloak_ruby",
    "documentation_uri" => "https://github.com/sergey-arkhipov/keycloak_ruby/blob/master/README.md",
    "changelog_uri" => "https://github.com/heartcombo/devise/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/sergey-arkhipov/keycloak_ruby",
    "bug_tracker_uri" => "https://github.com/sergey-arkhipov/keycloak_ruby/issues",
    "wiki_uri" => "",
    "rubygems_mfa_required" => "true"
  }
end
