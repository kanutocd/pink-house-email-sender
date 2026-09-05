# frozen_string_literal: true

require "json"
require "uri"

module Email
  module Sender
    module Providers
      # Mailgun HTTP adapter for transactional email delivery.
      class Mailgun < ProviderAdapter
        # Default Mailgun API base URL.
        BASE_URL = "https://api.mailgun.net"

        # Submit an email through Mailgun.
        # @param message [Message] validated email message
        # @return [Delivery] accepted provider response
        def deliver(message)
          validate_message(message)
          response = @http.request(:post, endpoint, headers: headers, body: request_body(message))
          map_response(response)
        end

        private

        def endpoint
          base_url = (configuration[:base_url] || BASE_URL).to_s.sub(%r{/+$}, "")
          domain = configuration[:domain]
          return "#{base_url}/messages" if domain.nil? && base_url.match?(%r{/v3/[^/]+\z})

          "#{base_url}/v3/#{required_setting(:domain)}/messages"
        end

        def headers
          {
            "Authorization" => "Basic #{basic_auth}",
            "Content-Type" => "application/x-www-form-urlencoded"
          }
        end

        def basic_auth
          ["api", required_setting(:api_key)].join(":").then { |value| [value].pack("m0") }
        end

        def request_body(message)
          email = email_metadata(message)
          fields = recipient_fields(email).merge(
            "subject" => email[:subject],
            "text" => email[:text],
            "html" => email[:html],
            "h:Reply-To" => email[:reply_to]
          )
          URI.encode_www_form(fields.compact)
        end

        def recipient_fields(email)
          {
            "from" => email[:from],
            "to" => email[:recipients].join(", "),
            "cc" => email[:cc].join(", "),
            "bcc" => email[:bcc].join(", ")
          }
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
