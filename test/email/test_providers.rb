# frozen_string_literal: true

require "test_helper"
require "email/sender/providers/mailpit"
require "email/sender/providers/resend"
require "email/sender/providers/mailgun"

module Email
  module Sender
    class TestProviders < Minitest::Test
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

      def setup
        @message = Message.new(
          from: "sender@example.test",
          to: ["one@example.test", "two@example.test"],
          subject: "Welcome",
          text: "Hello",
          html: "<p>Hello</p>"
        )
      end

      def test_mailpit_maps_a_json_request
        http = FakeHttp.new(body: { "ID" => "mailpit-123" })
        provider = Providers::Mailpit.new(configuration: configuration(:mailpit), http: http)

        delivery = provider.deliver(@message)

        assert_equal :accepted, delivery.status
        assert_equal "mailpit-123", delivery.provider_message_id
        assert_equal "http://localhost:8025/api/v1/send", http.requests.first[:url]
        assert_equal ["one@example.test", "two@example.test"], http.requests.first[:body]["To"]
      end

      def test_resend_maps_authentication_and_json_request
        http = FakeHttp.new
        provider = Providers::Resend.new(configuration: configuration(:resend, api_key: "secret"), http: http)

        delivery = provider.deliver(@message)

        assert_equal :accepted, delivery.status
        assert_equal "Bearer secret", http.requests.first[:headers]["Authorization"]
        assert_equal "Welcome", http.requests.first[:body]["subject"]
      end

      def test_resend_forwards_an_idempotency_key_from_message_metadata
        http = FakeHttp.new
        message = Message.new(
          from: "sender@example.test",
          to: "recipient@example.test",
          subject: "Welcome",
          text: "Hello",
          metadata: { idempotency_key: "request-123" }
        )
        provider = Providers::Resend.new(configuration: configuration(:resend, api_key: "secret"), http: http)

        provider.deliver(message)

        assert_equal "request-123", http.requests.first[:headers]["Idempotency-Key"]
      end

      def test_mailgun_maps_basic_auth_and_form_request
        http = FakeHttp.new
        provider = Providers::Mailgun.new(
          configuration: configuration(:mailgun, api_key: "secret", domain: "mg.example.test"), http: http
        )

        delivery = provider.deliver(@message)

        assert_equal :accepted, delivery.status
        assert_equal "Basic YXBpOnNlY3JldA==", http.requests.first[:headers]["Authorization"]
        assert_includes http.requests.first[:body], "subject=Welcome"
        assert_equal "https://api.mailgun.net/v3/mg.example.test/messages", http.requests.first[:url]
      end

      def test_provider_maps_http_failures_and_missing_configuration
        error_http = FakeHttp.new(status: 429, body: { "message" => "slow down" })
        provider = Providers::Resend.new(configuration: configuration(:resend, api_key: "secret"), http: error_http)

        error = assert_raises(Errors::RateLimited) { provider.deliver(@message) }
        assert_predicate error, :failover?
        assert_raises(Errors::ConfigurationError) do
          Providers::Resend.new(configuration: configuration(:resend), http: FakeHttp.new).deliver(@message)
        end
      end

      private

      def configuration(name, settings = {})
        ProviderConfiguration.new(name: name, settings: settings, capabilities: [:email])
      end
    end
  end
end
