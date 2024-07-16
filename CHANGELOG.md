## 8.3.5

- Small updates in source code documentation.
- Updates meta header for Elasticsearch Serverless.
- Fixes issues with ES_SERVERLESS_SERVICE_VERSION for backwards compatibility

## 8.3.3, 8.3.4 (yanked)

- Yanked due to errors.

## 8.3.2

- OpenTelemetry: In v8.3.0 and v8.3.1, the environment variable `OTEL_INSTRUMENTATION_ELASTICSEARCH_CAPTURE_SEARCH_QUERY` was available but is now deprecated in favor of `OTEL_RUBY_INSTRUMENTATION_ELASTICSEARCH_CAPTURE_SEARCH_QUERY`.

## 8.3.1

Tested versions of Ruby: (MRI) 3.0, 3.1, 3.2, 3.3, JRuby 9.3 and JRuby 9.4

- Removes unneccessary `require 'base64'` found thanks to warning in Ruby 3.3. So this removes the warning too if you were using Ruby 3.3.

## 8.3.0

Tested versions of Ruby: (MRI) 3.0, 3.1, 3.2, JRuby 9.3 and JRuby 9.4

This release adds native support for OpenTelemetry. Documentation will be added to [the official Transport documentation](https://www.elastic.co/guide/en/elasticsearch/client/ruby-api/current/transport.html). Pull Request: [#54](https://github.com/elastic/elastic-transport-ruby/pull/54).

## 8.2.4

Tested versions of Ruby: (MRI) 3.0, 3.1, 3.2, JRuby 9.3 and JRuby 9.4

- Fixes [#66](https://github.com/elastic/elastic-transport-ruby/issues/66) - Manticore transport unable to send custom headers with perform_request [Pull Request](https://github.com/elastic/elastic-transport-ruby/pull/69)
- Fixes [#67](https://github.com/elastic/elastic-transport-ruby/issues/67) - Float with many digits automatically becomes BigDecimal when using Oj. [Pull Request](https://github.com/elastic/elastic-transport-ruby/pull/68), thank you @kyoshidajp!

## 8.2.3

Tested versions of Ruby: (MRI) 3.0, 3.1, 3.2, JRuby 9.3 and JRuby 9.4

- Fixes enforcing UTF-8 in Response body, causing an error when the string is frozen, particularly when using webmock. [issue #63](https://github.com/elastic/elastic-transport-ruby/issues/63)

## 8.2.2

Tested versions of Ruby: (MRI) 3.0, 3.1, 3.2, JRuby 9.3 and JRuby 9.4

- Refactors `apply_headers` in base and manticore implementation: When passing in an object to the initializer, `apply_headers` would mutate this object and in certain conditions, this would raise `RuntimeError` in JRuby 9.3 and `ConcurrencyError` in JRuby 9.4. This update clones the options object instead.

## 8.2.1

Tested versions of Ruby: (MRI) 2.7, 3.0, 3.1, 3.2, JRuby 9.3 and JRuby 9.4. Ruby 2.7's end of life is coming in a few days, so this'll probably be the last release to test for Ruby 2.7.

- Fixes parsing ipv4 addresses like `inet[/127.0.0.1:9200]` in sniffer, [issue #48](https://github.com/elastic/elastic-transport-ruby/issues/48). [Pull Request](https://github.com/elastic/elastic-transport-ruby/pull/49) by [@robbat2](https://github.com/robbat2), thank you!

## 8.2.0

Tested versions of Ruby: (MRI) 2.7, 3.0, 3.1, 3.2, JRuby 9.3 and JRuby 9.4.

- Fixes [issue #44](https://github.com/elastic/elastic-transport-ruby/issues/44), raising `Elastic::Transport::Transport::Error` instead of `Faraday::ConnectionFailed` (or any other Faraday error class) when a host is unreachable.
- Removes development dependency on `ansi`, it hasn't been updated for years.
- Adds `rake console` task to run IRB with the Elastic transport client libraries loaded.
- General refactors, cleanup and updates in code for `base.rb` (The base class used by HTTP implementations Faraday, Manticore, Curb), `errors.rb`, `faraday.rb`, and more.

## 8.1.0

Adds support for Faraday version 2. From [Faraday's Upgrading guide](https://github.com/lostisland/faraday/blob/main/UPGRADING.md#faraday-20), the main change is the adapters have moved:

> With this release, we've officially moved all adapters, except for the net_http one, out of Faraday. What that means, is that they won't be available out-of-the-box anymore, and you'll instead need to add them to your Gemfile.
> If you just use the default net_http adapter, then you don't need to do anything!
> Otherwise, add the corresponding adapter gem to your Gemfile (e.g. faraday-net_http_persistent). Then, simply require them after you require faraday.

We're now supporting Faraday v2 and Faraday v1. The adapters were removed as development dependency in the gemspec and added to the Gemfile. A new file `Gemfile-faraday1.gemfile` was added to run tests with version `1.x` of Faraday too.

These are the gems required for the different adapters with Faraday 2, instead of the libraries on which they were based:
```
# HTTPCLient
'faraday-httpclient'

# NetHTTPPersistent
'faraday-net_http_persistent'

# Patron
'faraday-patron'

# Typhoeus
'faraday-typhoeus'
```

If you're using Faraday 1, you shouldn't have to change anything, but please [submit an issue](https://github.com/elastic/elastic-transport-ruby/issues) if you encounter any issues.

## 8.0.1

- Minor code cleanup
- Adds Elastic Transport service token, updates specs for meta header.

## 8.0.0

- Library renamed from [`elasticsearch-transport`](https://github.com/elastic/elasticsearch-ruby/tree/7.x/elasticsearch-transport) to `elastic-transport` and promoted to its own repository.
- Fixes tracing for Manticore [commit](https://github.com/elastic/elastic-transport-ruby/commit/98c81d19de4fee394f9c1a5079a1892ec951e0f9).
- Implements CA Fingerprinting [pull request](https://github.com/elastic/elastic-transport-ruby/pull/13)
- Adds `delay_on_retry` to wait between each failed connection, thanks @DinoPullerUqido! [commit](https://github.com/elastic/elastic-transport-ruby/commit/c2f8311409ca63a293588cb7eea5a0c672dbd436)
- Fixes compression, thanks @johnnyshields! [commit](https://github.com/elastic/elastic-transport-ruby/commit/8b326d643f76f037075500e19bbe096b2c298099)
- Tested in Ruby 3.1, JRuby 9.3, drops Ruby 2.5 in test Matrix. Version 8.0.0 tested for Ruby (MRI) 2.6, 2.7, 3.0 and 3.1 and JRuby 9.3.
- Updates Manticore implementation headers setup. When using the Manticore HTTP implementation, adding a custom `User-Agent` value in the headers on initialization would get overwritten. [Pull Request](https://github.com/elastic/elastic-transport-ruby/pull/22) - [Issue reported in elastic/elasticsearch-ruby#1684](https://github.com/elastic/elasticsearch-ruby/issues/1684).

# Changes from elasticsearch-transport:

## 7.14

 - Fixes for Manticore Implementation: Addresses custom headers on initialization (https://github.com/elastic/elasticsearch-ruby/commit/3732dd4f6de75365460fa99c1cd89668b107ef1c) and fixes tracing (https://github.com/elastic/elasticsearch-ruby/commit/3c48ebd9a783988d1f71bfb9940459832ccd63e4). Related to #1426 and #1428.

## 7.13

- Fixes thread safety issue in `get_connection` - [Pull Request](https://github.com/elastic/elasticsearch-ruby/pull/1325).

## 7.12

- Ruby 3 is now tested, it was added to the entire test suite.

## 7.11

- Fixes a bug with headers in our default Faraday class. [Commit](https://github.com/elastic/elasticsearch-ruby/commit/9c4afc452467cc6344359b54b98bbe5af1469219).

## 7.10

- Use 443 for default cloud port, 9200 as the default port for http
- Fixes a bug when building the complete endpoint URL could end with duplicate slashes `//`.
- Fixes a bug when building the complete endpoint URL with cloud id could end with duplicate ports [#1081](https://github.com/elastic/elasticsearch-ruby/issues/1081).

## 7.9
- Transport/Connection: Considers attributes values for equality - [Commit](https://github.com/elastic/elasticsearch-ruby/commit/06ffd03bf51f5f33a0d87e9914e66b39357d40af).
- When an API endpoint accepts both `GET` and `POST`, the client will always use `POST` when a request body is present.

## 7.8
- Surface deprecation headers from Elasticsearch. When there's a `warning` response header in Elasticsearch's response, the client will emit a warning with `warn`.
- Typhoeus is supported again, version 1.4+ and has been added back to the docs.
- Adds documentation and example for integrating with Elastic APM.

## 7.7

- Drops support for Ruby 2.4 since it's reached it's end of life.

## 7.6

### Faraday migrated to 1.0

We're now using version 1.0 of Faraday:
- The client initializer was modified but this should not disrupt final users at all, check [this commit](https://github.com/elastic/elasticsearch-ruby/commit/0fdc6533f4621a549a4cb99e778bbd827461a2d0) for more information.
- Migrated error checking to remove the deprecated `Faraday::Error` namespace.
- **This change is not compatible with [Typhoeus](https://github.com/typhoeus/typhoeus)**. The latest release is 1.3.1, but it's [still using the deprecated `Faraday::Error` namespace](https://github.com/typhoeus/typhoeus/blob/v1.3.1/lib/typhoeus/adapters/faraday.rb#L100). This has been fixed on master, but the last release was November 6, 2018. Version 1.4.0 should be ok once it's released.
- Note: Faraday 1.0 drops official support for JRuby. It installs fine on the tests we run with JRuby in this repo, but it's something we should pay attention to.

Reference: [Upgrading - Faraday 1.0](https://github.com/lostisland/faraday/blob/master/UPGRADING.md)

[Pull Request](https://github.com/elastic/elasticsearch-ruby/pull/808)

## 7.4

- Accept options passed to #perform_request to avoid infinite retry loop

## 7.3

- Add note to readme about the default port value
- Add note about exception to default port rule when connecting using Elastic Cloud ID
- Cluster name is variable in cloud id

## 7.2

- Support User-Agent header client team specification
- Improve code handling headers
- Handle headers when using JRuby and Manticore
- Rename method for clarity
- Test selecting connections using multiple threads
- Synchronize access to the connections collection and mutation of @current instance variable
- Fix specs for selecting a connection
- Further fixes to specs for testing selecting connections in parallel
- Support providing a cloud id
- Allow a port to be set with a Cloud id and use default if no port is provided
- Remove unnecessary check for cloud_id when setting default port
- Add documentation for creating client with cloud_id
- Allow compression with Faraday and supported http adapters
- Put development gem dependencies in gemspec
- No reason to use ! for decompress method name
- Check for the existence of headers before checking headers
- Apply compression headers manually based on general :compression option
- Use GZIP constant
- Group tests into their transport adapters
- Support compression when using Curb adapter
- Support compression when using Manticore adapter with JRuby
- Fix Curb unit test, expecting headers to be merged and not set
- Update test descriptions for compression settings
- Add documentation of 'compression' option on client
- Improve client documentation for compression option
- Centralize header handling into one method
- Only add Accept-Encoding header if compression option is true

## 7.1

- Use default port when host and protocol are specified but no port
- Verify that we have a response object before checking its status
- Make code more succinct for supporting host with path and no port
- Support options specified with String keys
- Update elasticsearch-transport/lib/elasticsearch/transport/client.rb
- Add tests showing IPv6 host specified when creating client

## 7.0

- Fixed failing integration test
- Updated the Manticore development dependency
- Fixed a failing Manticore unit test
- Removed "turn" and switched the tests to Minitest
- Fixed integration tests for Patron
- Allow passing request headers in `perform_request`
- Added integration test for passing request headers in `perform_request`
- Added, that request headers are printed in trace output, if set
- Fix typos in elasticsearch-transport/README.md
- Assert that connection count is at least previous count when reloaded
- Adjust test for change in default number of shards on ES 7
- Abstract logging functionality into a Loggable Module (#556)
- Convert client integration tests to rspec
- Add flexible configuration in spec helper
- Use helper methods in spec_helper
- Remove minitest client integration tests in favor of rspec test
- Convert tests to rspec and refactor client
- minor changes to the client specs
- Use pry-nav in development for JRuby
- Keep arguments variable name for now
- Skip round-robin test for now
- Mark test as pending until there is a better way to detect rotating nodes
- Remove client unit test in favor of rspec test
- Comment-out round-robin test as it occasionally passes and pending is ineffective
- Document the default host and port constant
- Add documentation to spec_helper methods
- Redacted password if host info is printed in error message
- Adds tests for not including password in logged error message
- The redacted string change will be in 6.1.1
- Add more tests for different ways to specify client host argument
- Do not duplicate connections in connection pool after rebuild (#591)
- Ensure that the spec rake task is run as part of integration tests
- Use constant to define Elasticsearch hosts and avoid yellow status when number of nodes is 1
- Update handling of publish_address in _nodes/http response
- Add another test for hostname/ipv6:port format

## 6.x

* Added default value 'application/json' for the 'Content-Type' header
* Added escaping of username and password in URL
* Added proper handling of headers in client options to the Manticore adapter
* Don't block waiting for body on HEAD requests
* Fixed double logging of failed responses
* Fixed incorrect test behaviour when the `QUIET` environment variable is set
* Fixed the bug with `nil` value of `retry_on_status`
* Fixed the incorrect paths and Typhoeus configuration in the benchmark tests
* Fixed the integration tests for client
* Fixed typo in default port handling during `__build_connections`
* Swallow logging of exceptions when the `ignore` is specified

## 5.x

* Added escaping of username and password in URL
* Don't block waiting for body on HEAD requests
* Fixed incorrect test behaviour when the `QUIET` environment variable is set
* Fixed double logging of failed responses
* Swallow logging of exceptions when the `ignore` is specified
* Fixed the bug with `nil` value of `retry_on_status`
* Added proper handling of headers in client options to the Manticore adapter
* Added default value 'application/json' for the 'Content-Type' header

## 2.x
* Fixed the bug with `nil` value of `retry_on_status`

## 1.x

* Fixed MRI 2.4 compatibility for 1.x
* Fixed failing integration test for keeping existing collections
* Fixed, that the clients tries to deserialize an empty body
* Fixed, that dead connections have not been removed during reloading, leading to leaks
* Fixed, that existing connections are not re-initialized during reloading ("sniffing")
* Added, that username and password is automatically escaped in the URL
* Changed, that the password is replaced with `*` characters in the log
* Bumped the "manticore" gem dependency to 0.5
* Improved the thread-safety of reloading connections
* Improved the Manticore HTTP client
* Fixed, that connections are reloaded _before_ getting a connection
* Added a better interface for configuring global HTTP settings such as protocol or authentication
* Added the option to configure the Faraday adapter using a block and the relevant documentation
* Added information about configuring the client for the Amazon Elasticsearch Service
* Added the `retry_on_status` option to retry on specific HTTP response statuses
* Changed, that transports can close connections during `__rebuild_connections`
* Added, that the Manticore adapter closes connections during reload ("sniffing")
* Added an argument to control clearing out the testing cluster
* Fixed, that reloading connections works with SSL, authentication and proxy/Shield
* Highlight the need to set `retry_on_failure` option with multiple hosts in documentation
* Added, that connection reloading supports Elasticsearch 2.0 output
* Improved thread safety in parts of connection handling code
* Cleaned up handling the `reload_connections` option for transport
* Be more defensive when logging exception
* Added, that the Manticore transport respects the `transport_options` argument
* Added a top level `request_timeout` argument
* Changed the argument compatibility check in `__extract_hosts()` from `respond_to?` to `is_a?`
* Document the DEFAULT_MAX_RETRIES value for `retry_on_failure`
* Leave only Typhoeus as the primary example of automatically detected & used HTTP library in README
* Make sure the `connections` object is an instance of Collection
* Prevent mutating the parameter passed to __extract_hosts() method
* Removed the `ipv4` resolve mode setting in the Curb adapter
* Update Manticore to utilize new SSL settings
* Updated the Curb integration test to not fail on older Elasticsearch versions
* Fixed, that the Curb transport passes the `selector_class` option
* Added handling the `::Curl::Err::TimeoutError` exception for Curb transport
* Reworded information about authentication and added example for using SSL certificates
* Added information about the `ELASTICSEARCH_URL` environment variable to the README
* Allow passing multiple URLs separated by a comma to the client
* Fixed an error where passing `host: { ... }` resulted in error in Client#__extract_hosts
* Added Manticore transport for JRuby platforms
* Fixed, that `ServerError` inherits from `Transport::Error`
* Fix problems with gems on JRuby
* Added the `send_get_body_as` setting
* Added support for automatically connecting to cluster set in the ELASTICSEARCH_URL environment variable
* Improved documentation
* Updated the parameters list for APIs (percolate, put index)
* Updated the "Indices Stats" API
* Improved the `__extract_parts` utility method
* Added, that error requests are properly logged and traced
* Fixed an error where exception was raised too late for error responses
* Added auto-detection for Faraday adapter from loaded Rubygems
