# frozen_string_literal: true

# lib/keycloak_ruby/request_performer.rb

module KeycloakRuby
  # Responsible for performing HTTP requests with HTTParty
  # and validating the response. This class helps to reduce
  # FeatureEnvy and keep the Client code cleaner.
  # :reek:FeatureEnvy
  class RequestPerformer
    def initialize(config)
      @config = config
    end

    # Executes an HTTP request and verifies the response code.
    #
    # @param request_params [KeycloakRuby::RequestParams] - an object containing
    #   :http_method, :url, :headers, :body, :success_codes, :error_class, :error_message
    #
    # @return [HTTParty::Response] The HTTParty response object on success.
    # @raise [request_params.error_class] If the response code is not in success_codes
    #   or HTTParty raises an error.
    def call(request_params)
      request_options = request_params.to_h.slice(:headers, :body)
      response = HTTParty.send(request_params.http_method, request_params.url, **request_options)
      verify_response!(response, request_params)
      response
    rescue HTTParty::Error => e
      message = e.message
      KeycloakRuby.logger.error("#{request_params.error_message} (HTTParty error): #{message}")
      raise request_params.error_class, message
    end

    private

    # Safe validation: returns true/false
    # :reek:UtilityFunction
    def verify_response(code, success_codes)
      case success_codes
      when Range
        success_codes.cover?(code)
      when Array
        success_codes.include?(code)
      else
        code == success_codes
      end
    end

    # Bang version that raises an error on invalid response
    def verify_response!(response, request_params)
      code = response.code
      return if verify_response(code, request_params.success_codes)

      message = request_params.error_message
      body = response.body
      KeycloakRuby.logger.error("#{message}: #{code} => #{body}")
      raise request_params.error_class, "#{message}: #{code} => #{body}"
    end
  end
end
