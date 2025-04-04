# frozen_string_literal: true

require File.expand_path("lib/keycloak_ruby/version", __dir__)
Gem::Specification.new do |spec|
  spec.name        = "keycloak_ruby"
  spec.version     = "0.0.1"
  spec.summary     = KeycloakRuby::Version
  spec.description = "Library for using keycloak with Rails"
  spec.authors     = ["Sergey Arkhipov", "Georgy Shcherbakov"]
  spec.email       = "sergey-arkhipov@ya.ru"
  spec.homepage    = "https://github.com/sergey-arkhipov/keycloak_ruby#"
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
  spec.metadata["rubygems_mfa_required"] = "true"
end
