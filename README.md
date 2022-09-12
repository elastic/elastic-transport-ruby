# Elastic Transport
[![Run tests](https://github.com/elastic/elastic-transport-ruby/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/elastic/elastic-transport-ruby/actions/workflows/tests.yml)

This gem provides a low-level Ruby client for connecting to an [Elastic](http://elastic.co) cluster. It powers both the [Elasticsearch client](https://github.com/elasticsearch/elasticsearch-ruby/) and the [Elastic Enterprise Search](https://github.com/elastic/enterprise-search-ruby/) client.

In the simplest form, connect to Elasticsearch running on `http://localhost:9200` without any configuration:

```ruby
require 'elastic/transport'

client = Elastic::Transport::Client.new
response = client.perform_request('GET', '_cluster/health')
# => #<Elastic::Transport::Transport::Response:0x007fc5d506ce38 @status=200, @body={ ... } >
```

**Refer to [the official documentation on Elastic Transport](https://www.elastic.co/guide/en/elasticsearch/client/ruby-api/current/transport.html).**

**Refer to [Advanced Configuration](https://www.elastic.co/guide/en/elasticsearch/client/ruby-api/current/advanced-config.html) to read about more configuration options.**

## Compatibility

This gem is compatible with maintained Ruby versions. See [Ruby Maintenance Branches](https://www.ruby-lang.org/en/downloads/branches/). We don't provide support to versions which have reached their end of life.

## Development and Community

For local development, clone the repository and run `bundle install`. See `rake -T` for a list of available Rake tasks for running tests, generating documentation, starting a testing cluster, etc.

Bug fixes and features must be covered by unit tests.

A rake task is included to launch an Elasticsearch cluster with Docker. You need to install docker on your system and then run:
```bash
$ rake docker:start[VERSION]
```

E.g.:
```bash
$ rake docker:start[8.0.0-alpha1]
```

You can find the available version in [Docker @ Elastic](https://www.docker.elastic.co/r/elasticsearch).

To run tests, launch a testing cluster and use the Rake tasks:

```bash
time rake test:unit
time rake test:integration
```

Use `COVERAGE=true` before running a test task to check coverage with Simplecov.

Github's pull requests and issues are used to communicate, send bug reports and code contributions.

## License

This software is licensed under the [Apache 2 license](./LICENSE).
