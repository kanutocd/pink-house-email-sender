# frozen_string_literal: true

require "json"

module Email
  module Sender
    module Providers
      # Mailpit HTTP adapter for local email development.
      class Mailpit < ProviderAdapter
        # Default Mailpit API base URL.
        BASE_URL = "http://localhost:8025"
        # Mailpit message submission endpoint.
        SEND_PATH = "/api/v1/send"

        # Submit an email to Mailpit.
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
          { "Content-Type" => "application/json" }
        end

        def request_body(message)
          email = email_metadata(message)
          {
            "From" => email[:from],
            "To" => email[:recipients],
            "Subject" => email[:subject],
            "Text" => email[:text],
            "HTML" => email[:html]
          }.compact
        end

        def map_response(response)
          map_http_error(response) unless response.successful?

          payload = response_payload(response)
          accepted_delivery(payload["ID"] || payload["id"], payload)
        end
      end
    end
  end
end
