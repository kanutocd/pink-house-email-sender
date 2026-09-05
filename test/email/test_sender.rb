# frozen_string_literal: true

require "test_helper"

module Email
  class TestSender < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Email::Sender::VERSION
    end

    def test_error_is_a_standard_error
      assert_operator Email::Sender::Error, :<, StandardError
    end

    def test_builds_a_core_message_from_email_input
      message = Email::Sender.build_message(
        from: " sender@example.test ",
        to: ["one@example.test", "two@example.test"],
        subject: "Welcome",
        text: "Hello",
        metadata: { request_id: "abc" }
      )

      assert_instance_of Email::Sender::Message, message
      assert_equal ["one@example.test", "two@example.test"], message.to
      assert_equal "Welcome", message.subject
      core_message = message.to_core_message

      assert_equal "one@example.test, two@example.test", core_message.to
      assert_equal "sender@example.test", core_message.metadata[:email][:from]
    end
  end
end
