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

require 'test_helper'

class Elastic::Transport::ClientAdaptersIntegrationTest < Minitest::Test
  context 'Adapters' do
    setup do
      begin
        Object.send(:remove_const, :Patron)
      rescue NameError
      end
    end

    should 'use the default Faraday adapter' do
      fork do
        client = Elastic::Transport::Client.new
        assert_equal(client.transport.connections.first.connection.adapter, Faraday::Adapter::NetHttp)
      end
    end

    should 'use Patron Faraday adapter' do
      fork do
        require 'faraday/patron'

        client = Elastic::Transport::Client.new
        assert_equal(client.transport.connections.first.connection.adapter, Faraday::Adapter::Patron)
      end
    end

    should 'use Typhoeus Faraday adapter' do
      fork do
        require 'faraday/typhoeus'

        client = Elastic::Transport::Client.new
        assert_equal(client.transport.connections.first.connection.adapter, Faraday::Adapter::Typhoeus)
      end
    end

    should 'use NetHttpPersistent Faraday adapter' do
      fork do
        require 'faraday/net_http_persistent'

        client = Elastic::Transport::Client.new
        assert_equal(client.transport.connections.first.connection.adapter, Faraday::Adapter::NetHttpPersistent)
      end
    end

    should 'use HTTPClient Faraday adapter' do
      fork do
        require 'faraday/httpclient'

        client = Elastic::Transport::Client.new
        assert_equal(client.transport.connections.first.connection.adapter, Faraday::Adapter::HTTPClient)
      end
    end
  end unless jruby?
end
