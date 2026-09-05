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
    # Shared provider configuration contract.
    ProviderConfiguration = ::Sender::Core::ProviderConfiguration
    # Shared provider adapter contract.
    Provider = ::Sender::Core::Provider
    # Shared normalized error namespace.
    Errors = ::Sender::Core::Errors

    # Namespace for email provider adapter implementations.
    module Providers
    end

    # Email-specific registry facade backed by sender-core.
    class ProviderRegistry < ::Sender::Core::ProviderRegistry
      # Email provider adapter paths included in the initial catalog.
      DEFAULT_PROVIDERS = {
        mailpit: "email/sender/providers/mailpit",
        resend: "email/sender/providers/resend",
        mailgun: "email/sender/providers/mailgun"
      }.freeze

      # @param catalog [Hash] email provider names mapped to adapter paths
      def initialize(catalog: DEFAULT_PROVIDERS)
        super(catalog: catalog, default_capabilities: [:email])
      end

      private

      def lazy_loader(path)
        lambda do
          require path
          constant_name = path.split("/").last.split("_").map(&:capitalize).join
          Providers.const_get(constant_name)
        end
      end
    end

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

    # @return [ProviderRegistry] process-local email provider registry
    def self.registry
      @registry ||= ProviderRegistry.new
    end

    # @return [Array<Symbol>] providers supported by the gem
    def self.providers
      registry.supported
    end

    # Configure one email provider.
    # @return [ProviderConfiguration] stored provider configuration
    def self.configure_provider(name, settings: {}, enabled: true, priority: 0, capabilities: nil)
      registry.configure(
        name,
        settings: settings,
        enabled: enabled,
        priority: priority,
        capabilities: capabilities
      )
    end
  end
end
