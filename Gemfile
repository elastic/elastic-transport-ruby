# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

source 'https://rubygems.org'

# Specify your gem's dependencies in elasticsearch-transport.gemspec
gemspec

group :development, :test do
  gem 'faraday-excon'
  gem 'faraday-httpclient'
  gem 'faraday-net_http_persistent'
  gem 'faraday-typhoeus'
  gem 'mutex_m' if RUBY_VERSION >= '3.4'
  gem 'opentelemetry-sdk', require: false if RUBY_VERSION >= '3.0'
  if defined?(JRUBY_VERSION)
    gem 'pry-nav'
  else
    gem 'async-http-faraday'
    gem 'faraday-patron'
    gem 'oj'
    gem 'pry-byebug'
  end
  gem 'rspec'
end
