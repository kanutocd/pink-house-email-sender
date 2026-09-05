# frozen_string_literal: true

module Email
  module Sender
    # Base behavior shared by email provider adapters.
    class ProviderAdapter < Provider
      # @param configuration [ProviderConfiguration] provider settings
      # @param http [HTTP::Client, nil] injectable HTTP client
      def initialize(configuration:, http: nil)
        super(configuration: configuration)
        @http = http || HTTP::Client.new(**http_options)
      end

      private

      def validate_message(message)
        return if message.is_a?(Message) ||
                  (message.is_a?(::Sender::Core::Message) && message.metadata.key?(:email))

        raise ArgumentError, "message must be an Email::Sender::Message"
      end

      def accepted_delivery(provider_message_id, metadata)
        Delivery.new(
          status: :accepted,
          provider: name,
          provider_message_id: provider_message_id,
          metadata: metadata
        )
      end

      def map_http_error(response, provider: name)
        category = case response.status
                   when 401 then :authentication
                   when 403 then :authorization
                   when 429 then :rate_limited
                   when 400, 422 then :invalid_request
                   when 500..599 then :provider_unavailable
                   else :provider_rejected
                   end
        error_class = Errors.const_get(category.to_s.split("_").map(&:capitalize).join)
        raise error_class.new(
          "#{provider} email request failed with HTTP #{response.status}: #{provider_error_detail(response)}",
          category: category, provider: provider
        )
      end

      def response_payload(response)
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        raise Errors::Unknown.new(
          "#{name} returned an invalid response", category: :malformed_response, provider: name
        )
      end

      def email_metadata(message)
        message.is_a?(Message) ? message.to_core_message.metadata.fetch(:email) : message.metadata.fetch(:email)
      end

      def idempotency_key(message)
        metadata = message.is_a?(Message) ? message.to_core_message.metadata : message.metadata
        metadata[:idempotency_key] || metadata["idempotency_key"]
      end

      def required_setting(key)
        value = configuration[key]
        return value.to_s unless value.nil? || value.to_s.empty?

        raise Errors::ConfigurationError.new(
          "#{name} #{key} is required", category: :configuration, provider: name
        )
      end

      def http_options
        %i[open_timeout read_timeout write_timeout total_timeout].to_h do |key|
          [key, configuration[key]]
        end.compact
      end

      def provider_error_detail(response)
        payload = JSON.parse(response.body.to_s)
        detail = payload["message"] || payload["error"]
        detail = detail["message"] if detail.is_a?(Hash)
        detail.to_s.strip[0, 500].then do |value|
          value.empty? ? "provider returned no diagnostic details" : value
        end
      rescue JSON::ParserError
        "provider returned an unstructured error response"
      end
    end
  end
end
