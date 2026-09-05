# frozen_string_literal: true

module Email
  module Sender
    # Immutable, validated email message at the channel boundary.
    class Message
      # @return [String] normalized sender address
      attr_reader :from
      # @return [Array<String>] normalized recipient addresses
      attr_reader :to
      # @return [String] normalized subject
      attr_reader :subject
      # @return [String, nil] plain-text body
      attr_reader :text
      # @return [String, nil] HTML body
      attr_reader :html
      # @return [Hash] normalized custom headers
      attr_reader :headers
      # @return [Array<Hash>] normalized attachments
      attr_reader :attachments
      # @return [Hash] application metadata
      attr_reader :metadata

      # @param from [String] sender email address
      # @param to [String, Array<String>] one or more recipients
      # @param subject [String] message subject
      # @param text [String, nil] plain-text body
      # @param html [String, nil] HTML body
      # @param headers [Hash] custom email headers
      # @param attachments [Array<Hash>] attachment descriptors
      # @param metadata [Hash] application metadata
      def initialize(from:, to:, subject:, text: nil, html: nil, headers: {}, attachments: [], metadata: {})
        @from = normalize_address(from, "from")
        @to = normalize_recipients(to)
        @subject = normalize_required_string(subject, "subject")
        @text = normalize_optional_body(text, "text")
        @html = normalize_optional_body(html, "html")
        raise ArgumentError, "text or html must be provided" unless @text || @html

        @headers = normalize_headers(headers)
        @attachments = normalize_attachments(attachments)
        @metadata = deep_freeze(validate_hash(metadata, "metadata"))
        freeze
      end

      # Convert the email message to the provider-neutral core contract.
      # @return [Sender::Core::Message] normalized core message
      def to_core_message
        body = text || html
        requirements = [:email]
        requirements << :html if html
        requirements << :attachments unless attachments.empty?

        ::Sender::Core::Message.new(
          to: to.join(", "),
          body: body,
          metadata: metadata.merge(
            email: {
              from: from,
              recipients: to,
              subject: subject,
              text: text,
              html: html,
              headers: headers,
              attachments: attachments
            }
          ),
          requirements: requirements
        )
      end

      private

      def normalize_recipients(value)
        values = value.is_a?(Array) ? value : [value]
        raise ArgumentError, "to must not be empty" if values.empty?

        values.map { |address| normalize_address(address, "to") }.freeze
      end

      def normalize_address(value, name)
        address = normalize_required_string(value, name)
        return address if address.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)

        raise ArgumentError, "#{name} must be a valid email address"
      end

      def normalize_required_string(value, name)
        raise ArgumentError, "#{name} must be a String" unless value.is_a?(String)

        normalized = value.strip
        raise ArgumentError, "#{name} must not be empty" if normalized.empty?

        normalized.freeze
      end

      def normalize_optional_body(value, name)
        return unless value

        raise ArgumentError, "#{name} must be a String" unless value.is_a?(String)
        raise ArgumentError, "#{name} must not be empty" if value.empty?

        value.dup.freeze
      end

      def normalize_headers(value)
        headers = validate_hash(value, "headers")
        headers.each_key do |key|
          raise ArgumentError, "header names must not contain newlines" if key.to_s.match?(/[\r\n]/)
        end
        deep_freeze(headers.transform_keys(&:to_s).transform_values(&:to_s))
      end

      def normalize_attachments(value)
        raise ArgumentError, "attachments must be an Array" unless value.is_a?(Array)

        deep_freeze(value.map do |attachment|
          data = validate_hash(attachment, "attachment")
          %i[filename content_type content].each do |key|
            raise ArgumentError, "attachment must include #{key}" unless data.key?(key) || data.key?(key.to_s)
          end
          data.transform_keys(&:to_sym)
        end)
      end

      def validate_hash(value, name)
        raise ArgumentError, "#{name} must be a Hash" unless value.is_a?(Hash)

        value.dup
      end

      def deep_freeze(value)
        case value
        when Hash
          value.each do |key, item|
            deep_freeze(key)
            deep_freeze(item)
          end
        when Array
          value.each { |item| deep_freeze(item) }
        end
        value.freeze
      end
    end
  end
end
