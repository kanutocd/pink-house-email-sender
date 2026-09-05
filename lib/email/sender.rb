# frozen_string_literal: true

require_relative "sender/version"
require "sender/core"
require_relative "sender/message"

# Top-level namespace for email-related libraries.
module Email
  # Namespace for the email-sender gem.
  module Sender
    # Base class for errors raised by the email-sender runtime.
    Error = ::Sender::Core::Error

    # Build an immutable email message for the delivery pipeline.
    # @return [Message] validated email message
    def self.build_message(from:, to:, subject:, text: nil, html: nil, headers: {}, attachments: [], metadata: {})
      Message.new(
        from: from,
        to: to,
        subject: subject,
        text: text,
        html: html,
        headers: headers,
        attachments: attachments,
        metadata: metadata
      )
    end
  end
end
