# email-sender

`email-sender` is a Ruby gem for provider-neutral email delivery. It is
designed to provide an email-oriented API while delegating shared delivery
contracts, routing, failover, resilience, state, and observability to
[`sender-core`](https://github.com/kanutocd/sender-core).

The email channel owns email validation, composition, provider adapters,
authentication, and provider payload mapping. It does not duplicate the
shared runtime or require a provider SDK.

## Status

The repository currently contains the gem foundation and implementation plan.
Email-specific message modeling and provider integrations are being developed
incrementally. See
[`IMPLEMENTATION_PLAN.md`](.ignoreme/codex/IMPLEMENTATION_PLAN.md) for the
planned phases.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem "email-sender"
```

Then install it with Bundler:

```bash
bundle install
```

## Intended usage

The public API will provide an email-friendly facade over the shared delivery
runtime:

```ruby
Email::Sender.deliver(
  from: "no-reply@example.test",
  to: "user@example.test",
  subject: "Welcome",
  text: "Welcome to the service"
)
```

The final message and provider APIs will be defined by the channel boundary
implementation. Invalid addresses, missing required fields, and unsupported
content must be rejected before provider election.

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
