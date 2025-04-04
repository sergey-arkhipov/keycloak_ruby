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
      # To reduce FeatureEnvy, extract local variables
      http_method   = request_params.http_method
      url           = request_params.url
      headers       = request_params.headers
      body          = request_params.body

      response = HTTParty.send(http_method, url, headers: headers, body: body)
      verify_response!(response, request_params)
      response
    rescue HTTParty::Error => e
      KeycloakRuby.logger.error("#{request_params.error_message} (HTTParty error): #{e.message}")
      raise request_params.error_class, e.message
    end

    private

    # Safe validation: returns true/false
    def verify_response(response, request_params)
      code          = response.code
      success_codes = request_params.success_codes

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
      return if verify_response(response, request_params)

      code          = response.code
      error_message = request_params.error_message
      KeycloakRuby.logger.error("#{error_message}: #{code} => #{response.body}")
      raise request_params.error_class, "#{error_message}: #{response.body}"
    end
  end
end
