## [Unreleased]

### Added

- Add the initial `Email::Sender` API with immutable email message validation
  and conversion to `sender-core` message contracts.
- Add lazy configuration and HTTP adapters for Mailpit, Resend, and Mailgun.
- Add provider-neutral routing with bounded failover, circuit protection,
  health tracking, attempt history, and structured router events.
- Add receipt normalization from provider payloads to `sender-core`
  `DeliveryEvent` objects.
- Add configurable HTTP timeouts for provider adapters.
- Add Resend `Idempotency-Key` forwarding from message metadata.
- Add operational, migration, rollback, and release documentation.

### Quality

- Add the `bundle exec rake` quality harness covering tests, RuboCop, RBS, and
  100% YARD documentation coverage.
- Verify the `email-sender` 0.1.0 package and its `sender-core` 0.1.0
  integration boundary.
- Add environment-based provider selection, default-provider priority, and
  JSON provider settings configuration.
