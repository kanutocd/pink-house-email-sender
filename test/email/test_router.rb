# frozen_string_literal: true

require "test_helper"

module Email
  class TestRouter < Minitest::Test
    class FailingProvider < Sender::Provider
      def deliver(_message)
        raise Sender::Errors::ProviderUnavailable.new(provider: name)
      end
    end

    class SuccessfulProvider < Sender::Provider
      def deliver(message)
        Sender::Delivery.new(status: :accepted, provider: name, metadata: message.metadata)
      end
    end

    class CountingProvider < SuccessfulProvider
      class << self
        attr_accessor :calls
      end

      def deliver(message)
        self.class.calls += 1
        super
      end
    end

    def test_public_email_api_fails_over_to_the_next_provider
      registry = Email::Sender::ProviderRegistry.new(catalog: {})
      registry.register(:primary, loader: -> { FailingProvider }, capabilities: [:email])
      registry.register(:secondary, loader: -> { SuccessfulProvider }, capabilities: [:email])
      registry.configure(:primary, priority: 10)
      registry.configure(:secondary, priority: 1)
      with_registry(registry) do
        delivery = Email::Sender.deliver(
          from: "sender@example.test",
          to: "recipient@example.test",
          subject: "Hello",
          text: "Message"
        )

        assert_equal :accepted, delivery.status
        assert_equal :secondary, delivery.provider
        statuses = delivery.attempts.map { |attempt| attempt[:status] }

        assert_equal %i[failed accepted], statuses
      end
    end

    def test_invalid_email_is_rejected_before_a_provider_is_called
      CountingProvider.calls = 0
      registry = Email::Sender::ProviderRegistry.new(catalog: {})
      registry.register(:counting, loader: -> { CountingProvider }, capabilities: [:email])
      registry.configure(:counting)

      with_registry(registry) do
        assert_raises(ArgumentError) do
          Email::Sender.deliver(
            from: "sender@example.test",
            to: "not-an-email",
            subject: "Hello",
            text: "Message"
          )
        end
      end

      assert_equal 0, CountingProvider.calls
    end

    private

    def with_registry(registry)
      previous = Email::Sender.instance_variable_get(:@registry)
      Email::Sender.instance_variable_set(:@registry, registry)
      yield
    ensure
      Email::Sender.instance_variable_set(:@registry, previous)
    end
  end
end
