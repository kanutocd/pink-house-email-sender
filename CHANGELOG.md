## [Unreleased]

### Added

- Support multiple named instances of the same email provider adapter with
  independent settings and runtime state.
- Identify catalog providers with advisory `support_level` metadata; values are
  informational and never prevent provider use.
- Preserve bounded provider diagnostic details in normalized HTTP errors to
  make rejected deliveries actionable without exposing credentials.
- Treat Resend sandbox testing-recipient restrictions as failover-eligible so
  local providers such as Mailpit can handle the message.
- Send Resend `reply_to` values in the string format required by the provider,
  omitting the field when no reply-to address is configured.
- Treat Mailgun sandbox recipient-forbidden responses as failover-eligible
  provider failures while retaining non-failover handling for other
  authorization errors.
- Declare HTML support for the initial Mailpit, Resend, and Mailgun provider
  catalog so HTML email messages can be elected and delivered.
- Add the initial `Email::Sender` API with immutable email message validation
  and conversion to `sender-core` message contracts.
- Add lazy configuration and HTTP adapters for Mailpit, Resend, and Mailgun.
- Add provider-neutral routing with bounded failover, circuit protection,
  health tracking, attempt history, and structured router events.
- Add receipt normalization from provider payloads to `sender-core`
  `DeliveryEvent` objects.
- Add configurable HTTP timeouts for provider adapters.
- Add Resend `Idempotency-Key` forwarding from message metadata.
- Include the required `User-Agent` header in Resend requests.
- Accept Mailgun sandbox endpoints with the domain embedded in `base_url` and
  preserve display-name sender addresses for provider payloads.
- Add operational, migration, rollback, and release documentation.

### Quality

- Add the `bundle exec rake` quality harness covering tests, RuboCop, RBS, and
  100% YARD documentation coverage.
- Verify the `email-sender` 0.1.0 package and its `sender-core` 0.1.0
  integration boundary.
- Add environment-based provider selection, default-provider priority, and
  JSON provider settings configuration.
