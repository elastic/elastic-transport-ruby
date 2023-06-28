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

    let(:otel) do
      described_class.new
    end

    let(:tracer) { otel.tracer }

    it 'creates a span' do
      client.perform_request(
        'DELETE', '/foo,bar/_aliases/abc,xyz', nil, nil, nil, ["/{index}/_alias/{name}", "/{index}/_aliases/{name}"],
        'indices.delete_alias'
      ) rescue

      expect(span.name).to eql('indices.delete_alias')
      expect(span.attributes['db.elasticsearch.path_parts.index']).to eql('foo,bar')
      expect(span.attributes['db.elasticsearch.path_parts.name']).to eq('abc,xyz')
      expect(span.attributes['db.operation']).to eq('indices.delete_alias')
      expect(span.attributes['db.statement']).to be_nil
      expect(span.attributes['http.request.method']).to eq('DELETE')
      expect(span.attributes['server.address']).to eq('localhost')
      expect(span.attributes['server.port']).to eq(9200)
    end
  end
end
