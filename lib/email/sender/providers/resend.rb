# frozen_string_literal: true

require "json"

module Email
  module Sender
    module Providers
      # Resend HTTP adapter for transactional email delivery.
      class Resend < ProviderAdapter
        # Default Resend API base URL.
        BASE_URL = "https://api.resend.com"
        # Resend email submission endpoint.
        SEND_PATH = "/emails"

        # Submit an email through Resend.
        # @param message [Message] validated email message
        # @return [Delivery] accepted provider response
        def deliver(message)
          validate_message(message)
          response = @http.request(:post, endpoint, headers: headers, body: request_body(message))
          map_response(response)
        end

        private

        def endpoint
          "#{configuration[:base_url] || BASE_URL}#{SEND_PATH}"
        end

        def headers
          { "Authorization" => "Bearer #{required_setting(:api_key)}", "Content-Type" => "application/json" }
        end

        def request_body(message)
          email = email_metadata(message)
          {
            "from" => email[:from],
            "to" => email[:recipients],
            "subject" => email[:subject],
            "text" => email[:text],
            "html" => email[:html]
          }.compact
        end

        def map_response(response)
          map_http_error(response) unless response.successful?

          payload = response_payload(response)
          accepted_delivery(payload["id"], payload)
        end
      end
    end
  end
end
