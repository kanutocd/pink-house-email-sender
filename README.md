# email-sender

`email-sender` is a Ruby gem for provider-neutral email delivery. It is
designed to provide an email-oriented API while delegating shared delivery
contracts, routing, failover, resilience, state, and observability to
[`sender-core`](https://github.com/kanutocd/sender-core).

The email channel owns email validation, composition, provider adapters,
authentication, and provider payload mapping. It does not duplicate the
shared runtime or require a provider SDK.

## Origin

`email-sender` was extracted from the Pink House SaaS project so its email
delivery capability could be reused independently of the application. Shared
delivery contracts and runtime behavior live in
[`sender-core`](https://github.com/kanutocd/sender-core); this gem owns email
validation, composition, provider adapters, and email-specific request and
response mapping.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem "email-sender"
```

Then install it with Bundler:

```bash
bundle install
```

To configure providers from environment variables, list the desired providers
and identify the preferred default. The default receives the highest election
priority; other selected providers remain available for failover:

```bash
EMAIL_SENDER_PROVIDERS=mailpit,resend
EMAIL_SENDER_DEFAULT_PROVIDER=resend
EMAIL_SENDER_RESEND_SETTINGS='{"api_key":"..."}'
```

Call `Email::Sender.configure_from_env` during application boot. Each
provider's `*_SETTINGS` value is a JSON object whose keys match that adapter's
settings.

## Usage

Deliver an email through the provider-neutral runtime:

```ruby
Email::Sender.deliver(
  from: "no-reply@example.test",
  to: "user@example.test",
  subject: "Welcome",
  text: "Welcome to the service"
)
```

Invalid addresses, missing required fields, and unsupported content are
rejected before provider election.

## Architecture

```text
Email::Sender facade
        |
email validation and composition
        |
sender-core Message -> Router -> email provider adapter -> provider API
                              |
                  health, failover, state, observability
```

Email provider adapters remain thin and independently testable. They translate
validated email data to provider requests and map responses and failures to
`sender-core` contracts.

## Public API and migration notes

Use `Email::Sender.build_message` when a validated immutable message is needed
before delivery. Use `Email::Sender.configure_provider` to register provider
settings, then call `Email::Sender.deliver`. The supported provider names are
`mailpit`, `resend`, and `mailgun`.

Provider selection and failover are delegated to `sender-core`; applications
should inspect the returned `Delivery` status, provider message ID, and attempt
history rather than relying on adapter-specific response objects. Receipt
payloads are normalized with `Email::Sender::Receipt.from`.

To migrate from an earlier development snapshot, replace direct adapter calls
with the facade, preserve provider credentials in application secrets, and
persist the returned provider message ID for receipt correlation. Existing
email validation errors should be handled at the call boundary because they
remain terminal.

For rollback, disable the affected provider in its configuration or select a
previously configured provider explicitly. Keep the shared `sender-core`
version compatible with the `~> 0.1` dependency constraint and do not replay
accepted submissions without an idempotency key.

## Development

Install development dependencies with:

```bash
bin/setup
```

Run the complete quality harness with:

```bash
bundle exec rake
```

The harness runs tests, RuboCop, RBS validation, YARD generation, and a 100%
YARD documentation coverage check. Tests must be deterministic and must not
require credentials, network access, or live email provider availability.

## Operations

Provider adapters use `sender-core`'s bounded HTTP client. Configure
`open_timeout`, `read_timeout`, `write_timeout`, and, when needed,
`total_timeout` in provider settings; values are expressed in seconds.
Retryable provider failures are classified by `sender-core`, which bounds
failover and records attempt history. Channel validation and invalid provider
requests remain terminal.

Credentials belong in application configuration or environment-backed secret
stores and must not be committed. The adapters do not log authorization
headers. For Resend, applications can supply `metadata: { idempotency_key: "..." }`
to forward an `Idempotency-Key` header when retrying a submission. Provider
message IDs should be treated as the correlation key for receipts.

Receipt payloads can be normalized without live webhook infrastructure:

```ruby
event = Email::Sender::Receipt.from(
  provider: :resend,
  provider_message_id: "message-123",
  payload: { "status" => "delivered" }
)
```

Pass the resulting `sender-core` delivery event to the relevant delivery
state owned by the application. Router attempt, failover, circuit, and health
events are available through `Email::Sender::Router#events`.

Useful individual tasks include:

```bash
bundle exec rake test
bundle exec rake rubocop
bundle exec rake rbs
bundle exec rake yard
bundle exec rake yard:coverage
bundle exec rake build
bin/console
```

## Design principles

- Keep email-specific behavior in this gem and shared behavior in
  `sender-core`.
- Validate before provider election and classify errors explicitly.
- Preserve immutable delivery context and attempt history.
- Keep adapters thin, lazy-loaded, and independent of live services.
- Prefer standard-library boundaries and minimal production dependencies.
- Keep receipts and webhook parsing separate from outbound sending.

## Contributing

Bug reports and pull requests are welcome at
[github.com/kanutocd/email-sender](https://github.com/kanutocd/email-sender).
Meaningful user, operator, integration, tooling, and architectural changes
should be recorded in `CHANGELOG.md` under `Unreleased`.

## License

This project is available under the [MIT License](LICENSE.txt).

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community guidelines.
