# Elastic Transport
[![Run tests](https://github.com/elastic/elastic-transport-ruby/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/elastic/elastic-transport-ruby/actions/workflows/tests.yml)

This gem provides a low-level Ruby client for connecting to an [Elastic](http://elastic.co) cluster. It powers the [Elasticsearch client](https://github.com/elasticsearch/elasticsearch-ruby/) and other Elastic projects.

In the simplest form, connect to Elasticsearch running on `http://localhost:9200` without any configuration:

```ruby
require 'elastic/transport'

client = Elastic::Transport::Client.new
response = client.perform_request('GET', '_cluster/health')
# => #<Elastic::Transport::Transport::Response:0x007fc5d506ce38 @status=200, @body={ ... } >
```

**Refer to [the official documentation on Elastic Transport](https://www.elastic.co/docs/reference/elasticsearch/clients/ruby/transport).**

**Refer to [Advanced Configuration](https://www.elastic.co/docs/reference/elasticsearch/clients/ruby/advanced-config) to read about more configuration options.**

## Compatibility

This gem is compatible with maintained Ruby versions. See [Ruby Maintenance Branches](https://www.ruby-lang.org/en/downloads/branches/). We don't provide support to versions which have reached their end of life.

## Development and Community

See [CONTRIBUTING](./CONTRIBUTING.md).

## License

This software is licensed under the [Apache 2 license](./LICENSE).
