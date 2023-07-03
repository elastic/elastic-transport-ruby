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
if ENV['COVERAGE'] && ENV['CI'].nil?
  require 'simplecov'
  SimpleCov.start { add_filter %r{^/test|spec/} }
end

require 'elastic-transport'
require 'logger'
require 'hashie/mash'
if defined?(JRUBY_VERSION)
  require 'elastic/transport/transport/http/manticore'
  require 'pry-nav'
else
  require 'pry-byebug'
  require 'elastic/transport/transport/http/curb'
  require 'curb'
end

# The hosts to use for creating a elasticsearch client.
#
# @since 7.0.0
ELASTICSEARCH_HOSTS = if (hosts = ENV['TEST_ES_SERVER'] || ENV['ELASTICSEARCH_HOSTS'])
                        hosts.split(',').map do |host|
                          /(http\:\/\/)?(\S+)/.match(host)[2]
                        end
                      else
                        ['localhost:9200']
                      end.freeze

TEST_HOST, TEST_PORT = ELASTICSEARCH_HOSTS.first.split(':') if ELASTICSEARCH_HOSTS

# Are we testing on JRuby?
#
# @return [ true, false ] Whether JRuby is being used.
#
# @since 7.0.0
def jruby?
  RUBY_PLATFORM =~ /\bjava\b/
end

# The names of the connected nodes.
#
# @return [ Array<String> ] The node names.
#
# @since 7.0.0
def node_names
  $node_names ||= default_client.perform_request('GET', '_nodes/stats').body['nodes'].collect do |name, stats|
    stats['name']
  end
end

# The default client.
#
# @return [ Elastic::Transport::Client ] The default client.
#
# @since 7.0.0
def default_client
  $client ||= Elastic::Transport::Client.new(hosts: ELASTICSEARCH_HOSTS)
end

def is_faraday_v2?
  Gem::Version.new(Faraday::VERSION) >= Gem::Version.new(2)
end

module Config
  def self.included(context)
    # Get the hosts to use to connect an elasticsearch client.
    #
    # @since 7.0.0
    context.let(:hosts) { ELASTICSEARCH_HOSTS }
  end
end

RSpec.configure do |config|
  config.include(Config)
  config.formatter = 'documentation'
  config.color = true
end

if ENV['TEST_WITH_OTEL'] == 'true'
  require 'opentelemetry-sdk'
  EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
  span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

  OpenTelemetry::SDK.configure do |c|
    c.error_handler = ->(exception:, message:) { raise(exception || message) }
    c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
    c.add_span_processor span_processor
  end
end
