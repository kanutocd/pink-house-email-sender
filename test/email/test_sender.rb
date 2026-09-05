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

    def test_exposes_the_initial_email_provider_catalog_without_loading_adapters
      with_fresh_registry do
        assert_equal %i[mailpit resend mailgun], Sender.providers
        assert_equal :fully_tested, Sender.provider_metadata(:mailpit).fetch(:support_level)
        assert_empty Sender.registry.configured
      end
    end

    def test_configures_a_provider_without_loading_its_adapter
      with_fresh_registry do
        configuration = Sender.configure_provider(:mailpit, settings: { base_url: "http://localhost:8025" })

        assert_equal :mailpit, configuration.name
        assert_equal "http://localhost:8025", configuration[:base_url]
        assert_equal %i[email html], configuration.capabilities
      end
    end

    def test_delivers_through_the_shared_router
      provider = Class.new(Email::Sender::Provider) do
        def deliver(message)
          Email::Sender::Delivery.new(status: :accepted, provider: name, metadata: message.metadata)
        end
      end
      registry = Email::Sender::ProviderRegistry.new(catalog: {})
      registry.register(:fake, loader: -> { provider }, capabilities: [:email])
      registry.configure(:fake)

      delivery = Email::Sender::Router.new(registry: registry).deliver(
        Email::Sender::Message.new(
          from: "sender@example.test", to: "recipient@example.test", subject: "Hi", text: "Hello"
        )
      )

      assert_equal :accepted, delivery.status
      assert_equal :fake, delivery.provider
    end

    def test_configures_selected_providers_and_default_from_environment
      with_fresh_registry do
        Sender.registry.register(:first, loader: -> { Email::Sender::Provider })
        Sender.registry.register(:second, loader: -> { Email::Sender::Provider })

        Sender.configure_from_env(
          env: {
            "EMAIL_SENDER_PROVIDERS" => "first, second",
            "EMAIL_SENDER_DEFAULT_PROVIDER" => "second",
            "EMAIL_SENDER_FIRST_SETTINGS" => '{"token":"secret"}'
          }
        )

        assert_equal %i[first second], Sender.registry.configured
        priorities = Sender.registry.providers.to_h { |provider| [provider.name, provider.configuration.priority] }

        assert_operator priorities[:second], :>, priorities[:first]
        assert_equal "secret", Sender.registry.provider(:first).configuration[:token]
      end
    end

    def test_configures_multiple_instances_of_one_provider_from_environment
      with_fresh_registry do
        Sender.configure_from_env(
          env: {
            "EMAIL_SENDER_PROVIDERS" => "resend_primary,resend_backup",
            "EMAIL_SENDER_DEFAULT_PROVIDER" => "resend_primary",
            "EMAIL_SENDER_RESEND_PRIMARY_SETTINGS" => '{"api_key":"primary"}',
            "EMAIL_SENDER_RESEND_BACKUP_SETTINGS" => '{"api_key":"backup"}'
          }
        )

        assert_equal %i[resend_primary resend_backup], Sender.registry.configured
        assert_equal :resend, Sender.registry.provider_metadata(:resend_backup).fetch(:adapter)
        assert_equal "backup", Sender.registry.provider(:resend_backup).configuration[:api_key]
      end
    end

    private

    def with_fresh_registry
      previous = Email::Sender.instance_variable_get(:@registry)
      Email::Sender.instance_variable_set(:@registry, Email::Sender::ProviderRegistry.new)
      yield
    ensure
      Email::Sender.instance_variable_set(:@registry, previous)
    end
  end
end
