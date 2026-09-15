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

require 'timeout'

module Elastic
  module Transport
    module Transport
      # Generic client error
      #
      class Error < StandardError
        # The adapter-level exception this error was built from, when the client
        # wraps one (see {Errors::NetworkError}). `nil` otherwise.
        attr_reader :original_exception

        def initialize(message = nil, original_exception = nil)
          @original_exception = original_exception
          super(message)
        end
      end

      # Reloading connections timeout (1 sec by default)
      #
      class SnifferTimeoutError < Timeout::Error; end

      # Elastic server error (HTTP status 5xx)
      #
      class ServerError < Error; end

      module Errors
        # Raised when the request never produced an HTTP response.
        class NetworkError < Error; end

        # Error raised by the HTTP connection.
        class ConnectionError < NetworkError; end

        # DNS lookup for the host failed. Faraday reports it as a ConnectionError.
        class HostResolutionError < ConnectionError; end

        # Error raised during the TLS handshake.
        class SSLError < ConnectionError; end

        # The connection timed out during an operation.
        class ConnectionTimeout < NetworkError; end
      end

      HTTP_STATUSES = {
        300 => 'MultipleChoices',
        301 => 'MovedPermanently',
        302 => 'Found',
        303 => 'SeeOther',
        304 => 'NotModified',
        305 => 'UseProxy',
        307 => 'TemporaryRedirect',
        308 => 'PermanentRedirect',

        400 => 'BadRequest',
        401 => 'Unauthorized',
        402 => 'PaymentRequired',
        403 => 'Forbidden',
        404 => 'NotFound',
        405 => 'MethodNotAllowed',
        406 => 'NotAcceptable',
        407 => 'ProxyAuthenticationRequired',
        408 => 'RequestTimeout',
        409 => 'Conflict',
        410 => 'Gone',
        411 => 'LengthRequired',
        412 => 'PreconditionFailed',
        413 => 'RequestEntityTooLarge',
        414 => 'RequestURITooLong',
        415 => 'UnsupportedMediaType',
        416 => 'RequestedRangeNotSatisfiable',
        417 => 'ExpectationFailed',
        418 => 'ImATeapot',
        421 => 'TooManyConnectionsFromThisIP',
        426 => 'UpgradeRequired',
        429 => 'TooManyRequests',
        450 => 'BlockedByWindowsParentalControls',
        494 => 'RequestHeaderTooLarge',
        497 => 'HTTPToHTTPS',
        499 => 'ClientClosedRequest',

        500 => 'InternalServerError',
        501 => 'NotImplemented',
        502 => 'BadGateway',
        503 => 'ServiceUnavailable',
        504 => 'GatewayTimeout',
        505 => 'HTTPVersionNotSupported',
        506 => 'VariantAlsoNegotiates',
        510 => 'NotExtended'
      }.freeze

      ERRORS = HTTP_STATUSES.each_with_object({}) do |error, sum|
        status, name = error
        sum[status] = Errors.const_set name, Class.new(ServerError)
        sum
      end
    end
  end
end
