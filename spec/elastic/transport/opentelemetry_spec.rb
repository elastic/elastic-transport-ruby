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

require 'spec_helper'

if defined?(::OpenTelemetry)
  describe Elastic::Transport::OpenTelemetry do
    let(:exporter) { EXPORTER }
    before { exporter.reset }
    after { exporter.reset }
    let(:span) { exporter.finished_spans[0] }

    let(:client) do
      Elastic::Transport::Client.new(hosts: ELASTICSEARCH_HOSTS).tap do |_client|
        allow(_client).to receive(:__build_connections)
      end
    end

    let(:otel) { described_class.new }

    context 'when the client is created with a tracer provider' do
      let(:tracer_provider) do
        double('tracer_provider').tap do |tp|
          expect(tp).to receive(:tracer).with(
            Elastic::Transport::OpenTelemetry::OTEL_TRACER_NAME, Elastic::Transport::VERSION
          )
        end
      end

      it 'uses the tracer provider to get a tracer' do
        Elastic::Transport::Client.new(opentelemetry_tracer_provider: tracer_provider)
      end
    end

    context 'when path parameters' do
      before do
        client.perform_request('DELETE', '/users', nil, nil, nil)
      rescue
      end
      after do
        client.perform_request('DELETE', '/users', nil, nil, nil)
      rescue
      end

      it 'creates a span with path parameters' do
        client.perform_request(
          'POST', '/users/_create/abc', nil, { name: 'otel-test' }, nil,
          defined_params: {'index' => 'users', 'id' => 'abc'}, endpoint: 'create'
        )

        span = exporter.finished_spans.find { |s| s.name == 'create' }
        expect(span.name).to eql('create')
        expect(span.attributes['db.system']).to eql('elasticsearch')
        expect(span.attributes['db.elasticsearch.path_parts.index']).to eql('users')
        expect(span.attributes['db.elasticsearch.path_parts.id']).to eq('abc')
        expect(span.attributes['db.operation']).to eq('create')
        expect(span.attributes['db.statement']).to be_nil
        expect(span.attributes['http.request.method']).to eq('POST')
        expect(span.attributes['server.address']).to eq('localhost')
        expect(span.attributes['server.port']).to eq(TEST_PORT.to_i)
      end

      context 'with list a path parameter' do
        it 'creates a span with path parameters' do
          client.perform_request(
            'GET', '_cluster/state/foo,bar', {}, nil, {},
            { defined_params: { metric: ['foo', 'bar']}, endpoint: 'cluster.state' }
          )

          span = exporter.finished_spans.find { |s| s.name == 'cluster.state' }
          expect(span.name).to eql('cluster.state')
          expect(span.attributes['db.system']).to eql('elasticsearch')
          expect(span.attributes['db.elasticsearch.path_parts.metric']).to eql('foo,bar')
          expect(span.attributes['db.operation']).to eq('cluster.state')
          expect(span.attributes['db.statement']).to be_nil
          expect(span.attributes['http.request.method']).to eq('GET')
          expect(span.attributes['server.address']).to eq('localhost')
          expect(span.attributes['server.port']).to eq(TEST_PORT.to_i)
        end
      end
    end

    context 'when a request is instrumented' do
      let(:body) do
        { query: { match: { password: { query: 'secret'} } } }
      end

      it 'creates a span and omits db.statement' do
        client.perform_request('GET', '/_search', nil, body, nil, endpoint: 'search')

        expect(span.name).to eql('search')
        expect(span.attributes['db.system']).to eql('elasticsearch')
        expect(span.attributes['db.operation']).to eq('search')
        expect(span.attributes['db.statement']).to be_nil
        expect(span.attributes['http.request.method']).to eq('GET')
        expect(span.attributes['server.address']).to eq('localhost')
        expect(span.attributes['server.port']).to eq(TEST_PORT.to_i)
      end

      context 'when body is sanitized' do
        context 'no custom keys' do
          let(:sanitized_body) do
            { query: { match: { password: 'REDACTED' } } }
          end

          around(:example) do |ex|
            body_strategy = ENV[described_class::ENV_VARIABLE_BODY_STRATEGY]
            ENV[described_class::ENV_VARIABLE_BODY_STRATEGY]  = 'sanitize'
            ex.run
            ENV[described_class::ENV_VARIABLE_BODY_STRATEGY] = body_strategy
          end

          it 'sanitizes the body' do
            client.perform_request('GET', '/_search', nil, body, nil, endpoint: 'search')

            expect(span.attributes['db.statement']).to eq(sanitized_body.to_json)
          end
        end

        context 'with deprecated ENV variable' do
          let(:sanitized_body) do
            { query: { match: { password: 'REDACTED' } } }
          end

          around(:example) do |ex|
            body_strategy = ENV[described_class::ENV_VARIABLE_DEPRECATED_BODY_STRATEGY]
            ENV[described_class::ENV_VARIABLE_DEPRECATED_BODY_STRATEGY]  = 'sanitize'
            ex.run
            ENV[described_class::ENV_VARIABLE_DEPRECATED_BODY_STRATEGY] = body_strategy
          end

          it 'sanitizes the body' do
            client.perform_request('GET', '/_search', nil, body, nil, endpoint: 'search')

            expect(span.attributes['db.statement']).to eq(sanitized_body.to_json)
          end
        end

        context 'with custom keys' do
          let(:body) do
            { query: { match: { sensitive: { query: 'secret'} } } }
          end

          let(:sanitized_body) do
            { query: { match: { sensitive: 'REDACTED' } } }
          end

          around(:example) do |ex|
            body_strategy = ENV[described_class::ENV_VARIABLE_BODY_STRATEGY]
            ENV[described_class::ENV_VARIABLE_BODY_STRATEGY] = 'sanitize'

            keys = ENV[described_class::ENV_VARIABLE_BODY_SANITIZE_KEYS]
            ENV[described_class::ENV_VARIABLE_BODY_SANITIZE_KEYS] = 'sensitive'

            ex.run

            ENV[described_class::ENV_VARIABLE_BODY_STRATEGY] = body_strategy
            ENV[described_class::ENV_VARIABLE_BODY_SANITIZE_KEYS] = keys
          end

          it 'sanitizes the body' do
            client.perform_request('GET', '/_search', nil, body, nil, endpoint: 'search')

            expect(span.attributes['db.statement']).to eq(sanitized_body.to_json)
          end
        end
      end

      context 'when body strategy is set to raw' do
        let(:body) do
          { query: { match: { sensitive: { query: 'secret'} } } }
        end

        around(:example) do |ex|
          body_strategy = ENV[described_class::ENV_VARIABLE_BODY_STRATEGY]
          ENV[described_class::ENV_VARIABLE_BODY_STRATEGY]  = 'raw'
          ex.run
          ENV[described_class::ENV_VARIABLE_BODY_STRATEGY] = body_strategy
        end

        context 'when the body is a string' do
          it 'includes the raw body' do
            client.perform_request('GET', '/_search', nil, body.to_json, nil, endpoint: 'search')
            expect(span.attributes['db.statement']).to eq(body.to_json)
          end
        end

        context' when the body is a hash' do
          it 'includes the raw body' do
            client.perform_request('GET', '/_search', nil, body, nil, endpoint: 'search')
            expect(span.attributes['db.statement']).to eq(body.to_json)
          end
        end
      end

      context 'when body strategy is set to omit' do
        let(:body) do
          { query: { match: { sensitive: { query: 'secret'} } } }
        end

        around(:example) do |ex|
          body_strategy = ENV[described_class::ENV_VARIABLE_BODY_STRATEGY]
          ENV[described_class::ENV_VARIABLE_BODY_STRATEGY]  = 'omit'
          ex.run
          ENV[described_class::ENV_VARIABLE_BODY_STRATEGY] = body_strategy
        end

        it 'does not include anything' do
          client.perform_request('GET', '/_search', nil, body, nil, endpoint: 'search')
          expect(span.attributes['db.statement']).to be_nil
        end
      end

      context 'a non-search endpoint' do
        let(:body) do
          { query: { match: { something: "test" } } }
        end

        it 'does not capture db.statement' do
          client.perform_request(
            'POST', '_all/_delete_by_query', nil, body, nil, endpoint: 'delete_by_query'
          )

          expect(span.attributes['db.statement']).to be_nil
        end
      end

      context 'when no endpoint or defined params are provided' do
        it 'creates a span with default values' do
          client.perform_request(
            'GET', '_cluster/state/foo,bar', {}, nil, {}
          )

          span = exporter.finished_spans.find { |s| s.name == 'GET' }
          expect(span.name).to eql('GET')
          expect(span.attributes['db.system']).to eql('elasticsearch')
          expect(span.attributes['db.elasticsearch.path_parts']).to be_nil
          expect(span.attributes['db.operation']).to be_nil
          expect(span.attributes['db.statement']).to be_nil
          expect(span.attributes['http.request.method']).to eq('GET')
          expect(span.attributes['server.address']).to eq('localhost')
          expect(span.attributes['server.port']).to eq(TEST_PORT.to_i)
        end
      end
    end

    context 'when the ENV variable OTEL_RUBY_INSTRUMENTATION_ELASTICSEARCH_ENABLED is set' do
      context 'to true' do
        around do |ex|
          original_setting = ENV[described_class::ENV_VARIABLE_ENABLED]
          ENV[described_class::ENV_VARIABLE_ENABLED] = 'true'
          ex.run
          ENV[described_class::ENV_VARIABLE_ENABLED] = original_setting
        end

        it 'instruments' do
          client.perform_request('GET', '/_search', nil, nil, nil, endpoint: 'search')
          expect(span.name).to eq('search')
        end
      end

      context 'to false' do
        around do |ex|
          original_setting = ENV[described_class::ENV_VARIABLE_ENABLED]
          ENV[described_class::ENV_VARIABLE_ENABLED] = 'false'
          ex.run
          ENV[described_class::ENV_VARIABLE_ENABLED] = original_setting
        end

        it 'does not instrument' do
          client.perform_request('GET', '/_search', nil, nil, nil, endpoint: 'search')
          expect(span).to be_nil
        end
      end
    end

    describe Elastic::Transport::OpenTelemetry::Sanitizer do
      let(:key_patterns) { nil }

      context '#sanitize' do
        let(:body) do
          { query: { match: { password: "test" } } }
        end

        let(:expected_body) do
          { query: { match: { password: "REDACTED" } } }
        end

        it 'redacts sensitive values' do
          expect(described_class.sanitize(body, key_patterns)).to eq(expected_body)
        end

        context 'with specified key patterns' do
          let(:key_patterns) { [/something/] }

          let(:body) do
            { query: { match: { something: "test" } } }
          end

          let(:expected_body) do
            { query: { match: { something: "REDACTED" } } }
          end

          it 'redacts sensitive values' do
            expect(described_class.sanitize(body, key_patterns)).to eq(expected_body)
          end
        end
      end
    end
  end
end
