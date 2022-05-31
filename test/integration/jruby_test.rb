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

if JRUBY
  require 'elastic/transport/transport/http/manticore'

  class Elastic::Transport::ClientManticoreIntegrationTest < Minitest::Test
    context 'Transport' do
      setup do
        uri = URI(HOST)
        @host = {
          host: uri.host,
          port: uri.port,
          user: uri.user,
          password: uri.password
        }
      end

      should 'allow to customize the Faraday adapter to Manticore' do
        client = Elastic::Transport::Client.new(
          transport_class: Elastic::Transport::Transport::HTTP::Manticore,
          trace: true,
          hosts: [@host]
        )
        response = client.perform_request 'GET', ''
        assert_respond_to(response.body, :to_hash)
      end
    end
  end
end
