# Contributing to Elasticsearch Transport Ruby


This guide assumes Ruby is already installed. We follow Ruby’s own maintenance policy and officially support all currently maintained versions per [Ruby Maintenance Branches](https://www.ruby-lang.org/en/downloads/branches/). So we can't guarantee the code works for versions of Ruby that have reached their end of life.

To work on the code, clone the project first:

```
$ git clone git@github.com:elastic/elastic-transport-ruby.git
```

And run `bundle install` to install dependencies.

# Tests

There are several test tasks in the Rakefile, you can check them with `rake -T` from the project's root directory.

```bash
rake test:unit
rake test:spec
rake test:integration
```

Use `COVERAGE=true` before running a test task to check coverage with Simplecov.

Github's pull requests and issues are used to communicate, send bug reports and code contributions. Bug fixes and features must be covered by unit tests.

You need an Elasticsearch cluster running for integration tests. The tests will use the default host `localhost:9200`, but you can change this value by setting the environment variables `TEST_ES_SERVER` or `ELASTICSEARCH_HOSTS`:

```
$ TEST_ES_SERVER=host:port rake test:integration
```

A rake task is included to launch an Elasticsearch cluster with Docker. You need to install docker on your system and then run:
```bash
$ rake docker:start[VERSION]
```

E.g.:
```bash
$ rake docker:start[8.0.0-alpha1]
```

You can find the available version in [Docker @ Elastic](https://www.docker.elastic.co/r/elasticsearch).

# Contributing

The process for contributing is:

1. It is best to do your work in a separate Git branch. This makes it easier to synchronise your changes with [`rebase`](http://mislav.uniqpath.com/2013/02/merge-vs-rebase/).

2. Make sure your changes don't break any existing tests, and that you add tests for both bugfixes and new functionality.

3. **Sign the contributor license agreement.**
Please make sure you have signed the [Contributor License Agreement](https://www.elastic.co/contributor-agreement/). We are not asking you to assign copyright to us, but to give us the right to distribute your code without restriction. We ask this of all contributors in order to assure our users of the origin and continuing existence of the code. You only need to sign the CLA once.

4. Submit a pull request.
Push your local changes to your forked copy of the repository and submit a pull request. In the pull request, describe what your changes do and mention the number of the issue where discussion has taken place, eg “Closes #123″.
