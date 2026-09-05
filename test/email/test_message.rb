# frozen_string_literal: true

require "test_helper"

module Email
  module Sender
    class TestMessage < Minitest::Test
      def test_normalizes_and_freezes_email_fields
        message = Message.new(
          from: " sender@example.test ",
          to: " recipient@example.test ",
          subject: " Hello ",
          html: "<p>Hello</p>",
          headers: { "X-Request-ID" => 123 },
          attachments: [{ filename: "hello.txt", content_type: "text/plain", content: "Hello" }]
        )

        assert_equal "sender@example.test", message.from
        assert_equal ["recipient@example.test"], message.to
        assert_equal "Hello", message.subject
        assert_equal({ "X-Request-ID" => "123" }, message.headers)
        assert_equal :attachments, message.to_core_message.requirements.last
        assert_predicate message, :frozen?
        assert_predicate message.headers, :frozen?
      end

      def test_requires_valid_addresses_content_and_structures
        assert_raises(ArgumentError) { Message.new(from: "bad", to: "to@example.test", subject: "s", text: "b") }
        assert_raises(ArgumentError) { Message.new(from: "a@example.test", to: [], subject: "s", text: "b") }
        assert_raises(ArgumentError) { Message.new(from: "a@example.test", to: "b@example.test", subject: "s") }
        assert_raises(ArgumentError) do
          Message.new(from: "a@example.test", to: "b@example.test", subject: "s", text: "")
        end
        assert_raises(ArgumentError) do
          Message.new(from: "a@example.test", to: "b@example.test", subject: "s", text: "b", headers: [])
        end
        assert_raises(ArgumentError) do
          Message.new(from: "a@example.test", to: "b@example.test", subject: "s", text: "b", attachments: [{}])
        end
      end

      def test_rejects_header_injection
        assert_raises(ArgumentError) do
          Message.new(
            from: "a@example.test",
            to: "b@example.test",
            subject: "s",
            text: "b",
            headers: { "X-Bad\nHeader" => "value" }
          )
        end
      end
    end
  end
end
