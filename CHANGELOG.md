## [Unreleased]

- Add boilerplate files generated from the `bundle gem ...`
- Populate gem metadata and replace the generated README with the
  email-sender project overview.
- Add the complete `bundle exec rake` quality harness for tests, RuboCop, RBS,
  and 100% YARD documentation coverage.
- Define Mailpit, Resend, and Mailgun as the initial supported email provider
  set.
- Start Phase 1 with immutable email message validation and conversion to
  `sender-core` message contracts.
