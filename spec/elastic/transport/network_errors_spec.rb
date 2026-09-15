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

describe 'network errors' do
  let(:errors) { Elastic::Transport::Transport::Errors }
  let(:transport) { Elastic::Transport::Client.new(hosts: 'fake').transport }

  def wrap(exception)
    transport.send(:__host_unreachable_error, exception)
  end

  context 'the class hierarchy' do
    it 'keeps every network error rescuable as Transport::Error' do
      [
        errors::NetworkError,
        errors::ConnectionError,
        errors::HostResolutionError,
        errors::ConnectionTimeout,
        errors::SSLError
      ].each do |klass|
        expect(klass.ancestors).to include(Elastic::Transport::Transport::Error)
        expect(klass.ancestors).to include(errors::NetworkError)
      end
    end

    it 'mirrors the elastic-transport-python layout' do
      expect(errors::ConnectionError.superclass).to be(errors::NetworkError)
      expect(errors::ConnectionTimeout.superclass).to be(errors::NetworkError)
      expect(errors::SSLError.superclass).to be(errors::ConnectionError)
    end

    it 'groups DNS failures under connection errors' do
      expect(errors::HostResolutionError.ancestors).to include(errors::ConnectionError)
    end

    it 'does not catch a timeout when rescuing ConnectionError' do
      expect(errors::ConnectionTimeout.ancestors).not_to include(errors::ConnectionError)
    end
  end

  context 'when wrapping an adapter exception' do
    let(:original) { ::Faraday::ConnectionFailed.new('connection refused') }

    it 'keeps the original message' do
      expect(wrap(original).message).to eq('connection refused')
    end

    it 'exposes the original exception' do
      expect(wrap(original).original_exception).to be(original)
    end

    it 'keeps the original backtrace' do
      original.set_backtrace(['socket.rb:1:in `connect\''])
      expect(wrap(original).backtrace).to eq(['socket.rb:1:in `connect\''])
    end

    it 'falls back to NetworkError for an unmapped exception' do
      expect(wrap(Errno::ECONNREFUSED.new)).to be_an_instance_of(errors::NetworkError)
    end
  end

  context 'with the Faraday transport' do
    {
      ::Faraday::ConnectionFailed => 'ConnectionError',
      ::Faraday::TimeoutError => 'ConnectionTimeout',
      ::Faraday::SSLError => 'SSLError'
    }.each do |adapter_error, expected|
      it "maps #{adapter_error} to #{expected}" do
        expect(wrap(adapter_error.new('boom'))).to be_an_instance_of(errors.const_get(expected))
      end
    end

    it 'maps a timeout to ConnectionTimeout even though it subclasses ServerError' do
      skip 'this Faraday does not define ServerError' unless ::Faraday.const_defined?(:ServerError)

      expect(::Faraday::TimeoutError.ancestors).to include(::Faraday::ServerError)
      expect(wrap(::Faraday::TimeoutError.new('boom')))
        .to be_an_instance_of(errors::ConnectionTimeout)
      expect(wrap(::Faraday::ServerError.new('boom')))
        .to be_an_instance_of(errors::NetworkError)
    end

    it 'still answers host_unreachable_exceptions with an Array' do
      expect(transport.host_unreachable_exceptions).to be_an_instance_of(Array)
      expect(transport.host_unreachable_exceptions).to include(::Faraday::ConnectionFailed)
    end
  end

  context 'when a transport only overrides host_unreachable_exceptions' do
    let(:custom_error) { Class.new(StandardError) }

    let(:legacy_transport) do
      error_class = custom_error
      Class.new(Elastic::Transport::Transport::HTTP::Faraday) do
        define_method(:host_unreachable_exceptions) { [error_class] }
      end.new(hosts: [{ host: 'fake', port: 9200 }])
    end

    it 'still rescues the exceptions it declared' do
      expect(legacy_transport.host_unreachable_exceptions).to eq([custom_error])
    end

    it 'falls back to the generic NetworkError rather than raising' do
      error = legacy_transport.send(:__host_unreachable_error, custom_error.new('x'))
      expect(error).to be_an_instance_of(errors::NetworkError)
      expect(error).to be_a(Elastic::Transport::Transport::Error)
    end
  end

  context 'when the host cannot be reached' do
    let(:client) do
      Elastic::Transport::Client.new(
        host: 'http://localhost:59999',
        retry_on_failure: false,
        logger: double('logger', error?: false, warn?: false, fatal?: false, debug?: false)
      )
    end

    it 'raises a ConnectionError that is still a Transport::Error' do
      expect { client.perform_request('GET', '/') }
        .to raise_exception(Elastic::Transport::Transport::Errors::ConnectionError)
      expect { client.perform_request('GET', '/') }
        .to raise_exception(Elastic::Transport::Transport::Error)
    end

    it 'sets the original exception as the cause' do
      client.perform_request('GET', '/')
    rescue Elastic::Transport::Transport::Errors::ConnectionError => e
      expect(e.original_exception).to be_a(::Faraday::ConnectionFailed)
      expect(e.cause).to be(e.original_exception)
    end
  end
end
