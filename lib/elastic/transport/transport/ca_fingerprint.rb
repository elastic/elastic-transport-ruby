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

require 'openssl'
require 'socket'
require 'tempfile'

module Elastic
  module Transport
    module Transport
      # Makes the certificate matching the `ca_fingerprint` option the only trust anchor of every connection.
      #
      # Before the first request, the server's certificate chain is fetched once without verification. Only the
      # certificate whose fingerprint matches is kept, so the fetch itself needs no trust. The connections are then
      # rebuilt with that certificate as their only trusted certificate, and the HTTP library verifies the chain,
      # expiry and host name on every connection.
      #
      module CaFingerprint
        TRUST_SETTINGS = %i[ca_file ca_path cert_store truststore].freeze
        VERIFY_OFF = [false, :none, :disable].freeze

        private

        # The pinned certificate must be the only trust anchor. Other trust settings would be trusted next to it,
        # or silently replaced by it, and turning verification off would turn the pin off too.
        def validate_ca_fingerprint_options!
          [options[:ssl], options.dig(:transport_options, :ssl)].compact.each do |ssl|
            if VERIFY_OFF.include?(ssl[:verify]) || TRUST_SETTINGS.any? { |key| ssl.key?(key) }
              raise ArgumentError,
                    "ca_fingerprint can't be combined with :verify off or with #{TRUST_SETTINGS.join(', ')}"
            end
          end
        end

        def pin_ca_certificate!
          return if @ca_file

          @ca_pin_mutex.synchronize do
            return if @ca_file

            ca = fetch_pinned_certificate
            store = OpenSSL::X509::Store.new
            store.flags = OpenSSL::X509::V_FLAG_PARTIAL_CHAIN # the pinned certificate may be an intermediate
            store.add_cert(ca)
            # Curb, Manticore and libcurl-based Faraday adapters only accept a CA file
            ca_file = Tempfile.new(['ca_fingerprint', '.pem'])
            ca_file.write(ca.to_pem)
            ca_file.flush

            # New hashes, so the caller's option hashes aren't changed
            transport_options = options[:transport_options] || {}
            options[:transport_options] = transport_options.merge(
              ssl: (transport_options[:ssl] || {}).merge(cert_store: store, ca_file: ca_file.path)
            )
            options[:ssl] = (options[:ssl] || {}).merge(ca_file: ca_file.path) # Manticore reads top-level :ssl
            __rebuild_pinned_connections
            @ca_file = ca_file
          end
        end

        # Replaces every connection, so none built before the pin stays in use.
        def __rebuild_pinned_connections
          @state_mutex.synchronize do
            __close_connections
            @connections = __build_connections
          end
        end

        def fetch_pinned_certificate
          unless hosts.all? { |host| host[:protocol] == 'https' }
            raise Error, 'CA fingerprinting can\'t be configured over http'
          end

          fingerprint = options[:ca_fingerprint].delete(':').upcase
          chain = reachable_peer_cert_chain
          ca = chain.find { |cert| OpenSSL::Digest::SHA256.hexdigest(cert.to_der).upcase == fingerprint }
          ca or raise Error, 'Server certificate CA fingerprint does not match the value configured in ca_fingerprint'
        end

        # Takes the chain of the first host that answers. Every other host must chain to the same certificate, or
        # its connections fail verification.
        def reachable_peer_cert_chain
          hosts.each_with_index do |host, index|
            return peer_cert_chain(host)
          rescue SystemCallError, SocketError, IOError, OpenSSL::SSL::SSLError
            raise if index == hosts.size - 1
          end
        end

        def peer_cert_chain(host)
          context = OpenSSL::SSL::SSLContext.new
          context.verify_mode = OpenSSL::SSL::VERIFY_NONE
          socket = TCPSocket.new(host[:host], host[:port])
          ssl = OpenSSL::SSL::SSLSocket.new(socket, context)
          ssl.hostname = host[:host]
          ssl.connect
          ssl.peer_cert_chain
        ensure
          ssl&.close
          socket&.close
        end
      end
    end
  end
end
