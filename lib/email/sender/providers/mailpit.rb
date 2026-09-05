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
          address_fields(email).merge(
            "Subject" => email[:subject],
            "Text" => email[:text],
            "HTML" => email[:html]
          ).compact
        end

        def address_fields(email)
          {
            "From" => address_payload(email[:from]),
            "To" => email[:recipients].map { |recipient| address_payload(recipient) },
            "Cc" => email[:cc].map { |recipient| address_payload(recipient) },
            "Bcc" => email[:bcc],
            "ReplyTo" => email[:reply_to] && [address_payload(email[:reply_to])]
          }
        end

        def address_payload(address)
          match = address.match(/\A(.+?)\s*<([^<>\s]+)>\z/)
          return { "Email" => address } unless match

          { "Email" => match[2], "Name" => match[1].strip }
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
