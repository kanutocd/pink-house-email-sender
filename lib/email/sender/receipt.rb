# frozen_string_literal: true

module Email
  module Sender
    # Maps provider webhook or polling payloads into core delivery events.
    class Receipt
      # Provider receipt statuses mapped to sender-core delivery statuses.
      STATUS_MAP = {
        "queued" => :pending,
        "processing" => :pending,
        "sent" => :submitted,
        "accepted" => :accepted,
        "delivered" => :delivered,
        "bounced" => :failed,
        "failed" => :failed,
        "rejected" => :failed
      }.freeze

      # @param provider [Symbol, String] provider that emitted the receipt
      # @param payload [Hash] provider webhook or polling payload
      # @param provider_message_id [String, nil] explicit provider message ID
      # @param occurred_at [Time] receipt timestamp
      # @return [Sender::Core::DeliveryEvent] normalized delivery event
      def self.from(provider:, payload:, provider_message_id: nil, occurred_at: Time.now)
        validate_payload(payload)
        id = provider_message_id || message_id(payload)
        raise ArgumentError, "provider message ID is required" if id.to_s.empty?

        ::Sender::Core::DeliveryEvent.new(
          provider: provider,
          provider_message_id: id,
          status: normalized_status(payload),
          metadata: payload,
          occurred_at: occurred_at
        )
      end

      class << self
        private

        def validate_payload(payload)
          return if payload.is_a?(Hash)

          raise ArgumentError, "payload must be a Hash"
        end

        def message_id(payload)
          payload[:id] || payload["id"] || payload[:message_id] || payload["message_id"]
        end

        def normalized_status(payload)
          status = payload[:status] || payload["status"] || payload[:event] || payload["event"]
          STATUS_MAP.fetch(status.to_s.downcase, :unknown)
        end
      end
    end
  end
end
