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
      Elastic::Transport::Client.new.tap do |_client|
        allow(_client).to receive(:__build_connections)
      end
    end

    let(:otel) { described_class.new }

    context 'when path parameters' do
      before do
        client.perform_request(
          'DELETE', '/users', nil, nil, nil, ["/{index}"],
          'delete'
        )
      rescue
      end
      after do
        client.perform_request(
          'DELETE', '/users', nil, nil, nil, ["/{index}"],
          'delete'
        )
      rescue
      end

      it 'creates a span with path parameters' do
        client.perform_request(
          'POST', '/users/_create/abc', nil, { name: 'otel-test' }, nil, ["/{index}/_create/{id}"],
          'create'
        )

        span = exporter.finished_spans.find { |s| s.name == 'create' }
        expect(span.name).to eql('create')
        expect(span.attributes['db.elasticsearch.path_parts.index']).to eql('users')
        expect(span.attributes['db.elasticsearch.path_parts.id']).to eq('abc')
        expect(span.attributes['db.operation']).to eq('create')
        expect(span.attributes['db.statement']).to be_nil
        expect(span.attributes['http.request.method']).to eq('POST')
        expect(span.attributes['server.address']).to eq('localhost')
        expect(span.attributes['server.port']).to eq(9200)
      end
    end

    describe '#path_regexps' do
      let(:endpoint) { 'search' }
      let(:path_templates) { ["/_search", "/{index}/_search"] }

      it 'caches the regexps' do
        expect(described_class::ENDPOINT_PATH_REGEXPS['search']).to be_nil
        expect(otel.path_regexps(endpoint, path_templates)).to eq([/\/_search$/, /\/(?<index>[^\/]+)\/_search$/])
        expect(described_class::ENDPOINT_PATH_REGEXPS['search'][0]).to eq(/\/_search$/)
      end
    end

    context 'when a request is instrumented' do
      let(:body) do
        { query: { match: { password: { query: 'secret'} } } }
      end

      it 'creates a span and omits db.statement' do
        client.perform_request('GET', '/_search', nil, body, nil, ["/_search", "/{index}/_search"], 'search')

        expect(span.name).to eql('search')
        expect(span.attributes['db.operation']).to eq('search')
        expect(span.attributes['db.statement']).to be_nil
        expect(span.attributes['http.request.method']).to eq('GET')
        expect(span.attributes['server.address']).to eq('localhost')
        expect(span.attributes['server.port']).to eq(9200)
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
            client.perform_request('GET', '/_search', nil, body, nil, ["/_search", "/{index}/_search"], 'search')

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
            client.perform_request('GET', '/_search', nil, body, nil, ["/_search", "/{index}/_search"], 'search')

            expect(span.attributes['db.statement']).to eq(sanitized_body.to_json)
          end
        end
      end

      context 'a non-search endpoint' do
        let(:body) do
          { query: { match: { something: "test" } } }
        end

        it 'does not capture db.statement' do
          client.perform_request(
            'POST', '_all/_delete_by_query', nil, body, nil, ["/{index}/_delete_by_query"], 'delete_by_query'
          )

          expect(span.attributes['db.statement']).to be_nil
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
