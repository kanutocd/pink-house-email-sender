# frozen_string_literal: true

require "test_helper"

module Email
  module Sender
    class TestReceipt < Minitest::Test
      def test_maps_provider_receipt_to_a_core_delivery_event
        event = Receipt.from(
          provider: :mailgun,
          payload: { "id" => "message-123", "event" => "delivered", "recipient" => "one@example.test" },
          occurred_at: Time.utc(2026, 1, 1)
        )

        assert_equal :mailgun, event.provider
        assert_equal "message-123", event.provider_message_id
        assert_equal :delivered, event.status
        assert_equal "one@example.test", event.metadata["recipient"]
        assert_equal Time.utc(2026, 1, 1), event.occurred_at
      end

      def test_maps_failure_and_unknown_receipts
        failed = Receipt.from(provider: :resend, provider_message_id: "failed-1", payload: { status: "bounced" })
        unknown = Receipt.from(provider: :resend, provider_message_id: "unknown-1", payload: { status: "deferred" })

        assert_equal :failed, failed.status
        assert_equal :unknown, unknown.status
      end

      def test_requires_a_payload_and_provider_message_id
        assert_raises(ArgumentError) { Receipt.from(provider: :mailpit, payload: []) }
        assert_raises(ArgumentError) { Receipt.from(provider: :mailpit, payload: { status: "sent" }) }
      end
    end
  end
end
