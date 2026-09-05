# frozen_string_literal: true

require "test_helper"
require "email/sender/providers/resend"

module Email
  module Sender
    class TestResendProvider < Minitest::Test
      class FakeHttp
        attr_reader :requests

        def initialize(body: { "id" => "message-123" }, status: 202)
          @body = body
          @status = status
          @requests = []
        end

        def request(method, url, headers:, body:)
          @requests << { method: method, url: url, headers: headers, body: body }
          HTTP::Response.new(status: @status, body: JSON.generate(@body))
        end
      end

      def test_sends_reply_to_as_a_string
        http = FakeHttp.new
        provider = Providers::Resend.new(configuration:, http:)
        provider.deliver(build_message)

        assert_equal "reply@example.test", http.requests.first[:body]["reply_to"]
      end

      def test_treats_testing_recipient_restriction_as_failover_eligible
        http = FakeHttp.new(
          status: 422,
          body: { "message" => "Please use our testing email address instead of domains like `example.com`." }
        )
        provider = Providers::Resend.new(configuration:, http:)

        error = assert_raises(Errors::ProviderUnavailable) { provider.deliver(build_message) }

        assert_predicate error, :failover?
        assert_includes error.message, "testing recipient restriction"
      end

      private

      def configuration
        ProviderConfiguration.new(name: :resend, settings: { api_key: "secret" })
      end

      def build_message
        Message.new(
          from: "sender@example.test", to: "recipient@example.test", subject: "Hello", text: "Message",
          reply_to: "reply@example.test"
        )
      end
    end
  end
end
