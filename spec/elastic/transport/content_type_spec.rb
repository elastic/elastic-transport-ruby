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

describe Elastic::Transport::Client do
  let(:client) do
    described_class.new.tap do |client|
      allow(client).to receive(:__build_connections)
    end
  end

  context 'Client' do
    it 'sets the \'Content-Type\' header to \'application/json\' by default' do
      expect(client.transport.connections.first.connection.headers['Content-Type']).to eq('application/json')
    end
  end

  context 'when a Content-Type header is specified as client option' do
    let(:client) do
      described_class.new(transport_options: { headers: { 'Content-Type' => 'testing' } })
    end

    it 'sets the specified Content-Type header' do
      expect(client.transport.connections.first.connection.headers['Content-Type']).to eq('testing')
    end
  end

  context 'when a content-type header is specified as client option in lower-case' do
    let(:client) do
      described_class.new(transport_options: { headers: { 'content-type' => 'testing' } })
    end

    it 'sets the specified Content-Type header' do
      expect(client.transport.connections.first.connection.headers['Content-Type']).to eq('testing')
    end
  end

  if jruby?
    context 'when using JRuby' do
      let(:client) do
        Elastic::Transport::Client.new(
          transport_class: Elastic::Transport::Transport::HTTP::Manticore,
          transport_options: { headers: headers }
        )
      end

      let(:connection_headers) {
        client.transport.connections.connections.first.connection.instance_variable_get('@options')[:headers]
      }

      context 'when a Content-Type header is specified as client option' do
        let(:headers) { { 'Content-Type' => 'testing' } }

        it 'sets the specified Content-Type header' do
          expect(connection_headers['Content-Type']).to eq('testing')
        end
      end

      context 'when a content-type header is specified as client option in lower-case' do
        let(:headers) { { 'content-type' => 'testing' } }

        it 'sets the specified Content-Type header' do
          expect(connection_headers['Content-Type']).to eq('testing')
        end
      end
    end
  end
end
