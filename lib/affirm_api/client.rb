# frozen_string_literal: true

require 'net/http'

module AffirmApi
  # Interfaces with Hacker News API
  class Client
    def get(endpoint)
      App.logger.info "#{self.class}: GETing #{api_url}#{endpoint}"

      http, request = setup_request "#{api_url}#{endpoint}", :get
      response = http.request request
      # raise "AffirmApi::Client: Reponse Code #{response.code}" unless (200..300).include? response.code.to_i

      [request, JSON.parse(response.body)]
    end

    def post(endpoint, body={})
      App.logger.info "#{self.class}: POSTing #{api_url}#{endpoint}"

      http, request = setup_request "#{api_url}#{endpoint}", :post, body
      response = http.request request
      # raise "AffirmApi::Client: Reponse Code #{response.code}" unless (200..300).include? response.code.to_i

      [request, JSON.parse(response.body)]
    end

    private

    def setup_request(endpoint, method=:GET, body=nil)
      uri = URI endpoint
      http = Net::HTTP.start uri.host, uri.port, use_ssl: uri.scheme == 'https'
      http_method_class = Kernel.const_get "Net::HTTP::#{method.to_s.downcase.capitalize}"

      request = http_method_class.new uri
      request.body = body.to_json if body
      default_headers.each_pair { |key, value| request[key.to_s] = value }
      request.basic_auth public_api_key, private_api_key
      
      [http, request]
    end

    def default_headers
      { 'Content-Type': 'application/json' }
    end

    def api_url
      ENV.fetch 'AFFIRM_API_URL'
    end

    def public_api_key
      ENV.fetch 'AFFIRM_PUBLIC_API_KEY'
    end

    def private_api_key
      ENV.fetch 'AFFIRM_PRIVATE_API_KEY'
    end
  end
end
