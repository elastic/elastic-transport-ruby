# Notes for coding agents

## Running tests

- `bundle exec rake test:unit` (Minitest, `test/unit`) and `bundle exec rspec` (`spec/`) run without a cluster. CI also runs `test:integration` against Elasticsearch on `TEST_ES_SERVER` (default `http://localhost:9250`).
- Without a cluster, about 24 specs fail on a clean `main` (23 in `client_spec.rb` under "when the client connects to Elasticsearch", 1 `retry_on_failure` spec in `base_spec.rb`). Before you call a failure a regression, compare the list of failures with the list on `main`.
- Faraday 1 is still supported: `BUNDLE_GEMFILE=Gemfile-faraday1.gemfile bundle exec rake test:faraday1:spec`. Options added in Faraday 2 (for example `ssl: { verify_hostname: }`) raise `NoMethodError` on `Faraday::SSLOptions` in Faraday 1. Run both Gemfiles when you touch Faraday options.
- CI runs MRI 3.3 to 4.0 and JRuby 9.3 to 10.0. Manticore and its specs only run on JRuby, and Curb doesn't run on JRuby. If you can't run JRuby, say that Manticore is untested.
- Test TLS behaviour against an in-process `OpenSSL::SSL::SSLServer` with certificates generated in the spec (see "CA Fingerprinting" in `spec/elastic/transport/client_spec.rb`). Don't stub sockets, and don't write certificate files into the working directory.
- Curb isn't loaded on JRuby. A `HTTP::Curb` reference that runs while a spec file loads (outside `let`/`it`) breaks the whole file there, even when the context is skipped with `unless: jruby?`.
- TLS errors differ by adapter, platform and OpenSSL version (libcurl with OpenSSL 3.0 says `EVP lib` or `invalid padding`, JRuby only says `certificate verify failed`). In TLS specs, check that the test server received no request, and keep a passing control example, instead of matching the message.
- jruby-openssl differs from MRI's openssl: no `OpenSSL::X509::V_FLAG_PARTIAL_CHAIN`, no `OpenSSL::PKey::EC.generate` on JRuby 9.3, and on JRuby 9.3 and 9.4 it can't complete a handshake with an in-process `SSLServer` (JRuby 10 can). Use RSA keys in specs and guard optional constants with `defined?`.
- On `main`, the `jruby-9.4` unit tests already fail with json 3.x + multi_json 1.19 (`ArgumentError` in `JSON.parse`). That failure isn't caused by your change.
- `spec/elastic/transport/http/faraday_spec.rb` ("when compression enabled") compares gzip output, which contains a timestamp, so it fails now and then when the clock crosses a second. Rerun before you investigate.
- RSpec `if:`/`unless:` metadata on a nested context or example replaces the same key on an outer context, it doesn't combine with it. Repeat the outer condition, or use the other key.
- RSpec output has ANSI colours. Strip them (`sed 's/\x1b\[[0-9;]*m//g'`) before you grep for `^rspec`.

## Architecture

- `Client` builds the transport and passes `@arguments` to it as `options`. The top-level hash is a copy, but nested hashes such as `transport_options` are the caller's own objects. The client already adds the meta header to them. Don't write new state into nested caller hashes: assign a merged copy instead, so a caller can reuse its options for another client.
- Users change the transport after `Client.new` (for example chewy sets `client.transport.logger`). Never replace `client.transport` after construction. Rebuild connections inside the existing transport instead.
- `Base#__rebuild_connections` keeps an existing connection when it is `==` to a new one, and `Connection#==` compares only host, port, protocol and attributes. To make sure no old connection survives (for example after a TLS setting changes), replace `@connections` completely.
- Every transport builds connections in `__build_connection`, except Manticore. Manticore builds one `Manticore::Client` in `initialize` (`build_client`) and reads its SSL settings from the top-level `:ssl` option, not from `transport_options[:ssl]`. Changing SSL settings for Manticore means calling `build_client` again.
- Curb reads only what `__build_connection` copies to the `Curl::Easy`, so a new SSL option has to be mapped there explicitly.
- Each transport implements `perform_request` with a block that calls `Base#perform_request`. Logic that must run before every request (for example the CA pin) goes in `Base#perform_request`, so the sniffer and custom transports that include `Base` get it too.
- `Base#perform_request` turns the adapter exceptions listed in `host_unreachable_exceptions` into `Transport::Error` (#44, #45). Errors raised outside that path (for example a raw `Errno::ECONNREFUSED` from your own socket code) reach the caller unwrapped.

## Compatibility

- Gate support for a newer dependency on its version, and keep the old path (#112, multi_json `MultiJSON`). Don't use `Gem.loaded_specs[...]` for the check: it is `nil` when gems are loaded without RubyGems activation (`bundle install --standalone`, vendored load paths), which broke every request in 8.5.2 and 8.5.3 (#125, #128). Prefer feature detection (`defined?`, `respond_to?`).
- When you fix a deprecated call, `rg` for every call site. #112 fixed the serializer but missed `::MultiJson.adapter` in `Base#perform_request` (#125).
- Response bodies can be frozen (webmock freezes them). Don't mutate them in place (#63).
- Header names are case-sensitive in Manticore and Curb, unlike `Faraday::Utils::Headers`. Merge headers case-insensitively, or Elasticsearch rejects duplicate `Content-Type` headers (#115). Per-request headers must override constructor headers on every transport (#66).
- `s.files` in the gemspec packages `lib/**/*` and `*.md`, so every top-level Markdown file ships in the gem (#114).

## Security

- Never put credentials in logs, traces or OpenTelemetry spans. Use `sanitize_url` and `Redacted` hosts (#98).
- `ca_fingerprint` makes the matching certificate the only trust anchor, and the HTTP library verifies every data connection (chain, expiry, host name). Don't go back to checking that the fingerprint is *present* in the chain, and don't check it on a separate socket. Both were in the old implementation, and an on-path attacker could get past either one. The common attack is a forged leaf that names the real CA as its issuer (same subject and key identifier) but is signed with the attacker's key, sent with the public CA certificate appended. Only signature verification rejects it. The elastic-transport-python and elastic-transport-js checks accept this leaf as well (elastic/security#15815), so don't copy their approach for TLS without checking it against this attack first.
- Fail with an `ArgumentError` instead of warning when TLS options conflict. A warning is easy to miss, and the user ends up with no protection without knowing it.

## Process

- Breaking changes can ship in minor versions when security needs them, because minor versions follow the Elastic Stack version. Document every one in `CHANGELOG.md` under `## Unreleased`.
- Fixes are backported to the maintained `8.x` branches with `[8.x] Backports ...` PRs.
- Before you call another Elastic client "the reference", read its current code. The clients differ, and the shared design is not always secure.
