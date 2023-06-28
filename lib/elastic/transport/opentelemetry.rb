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

module Elastic
  module Transport
    class OpenTelemetry
      OTEL_TRACER_NAME = 'elasticsearch-api'
      ENDPOINT_PATH_REGEXPS = {}
      MUTEX = Mutex.new

      def initialize
        @tracer = ::OpenTelemetry.tracer_provider.tracer(OTEL_TRACER_NAME)
      end
      attr_accessor :tracer

      def path_regexps(endpoint, path_templates)
        return ENDPOINT_PATH_REGEXPS[endpoint] if ENDPOINT_PATH_REGEXPS.key?(endpoint)

        MUTEX.synchronize do
          return ENDPOINT_PATH_REGEXPS[endpoint] if ENDPOINT_PATH_REGEXPS.key?(endpoint)

          ENDPOINT_PATH_REGEXPS[endpoint] = path_templates.collect do |template|
            Regexp.new(template.gsub('{', '(?<').gsub('}', '>[^/]+)') + '$')
          end
        end
        ENDPOINT_PATH_REGEXPS[endpoint]
      end
    end
  end
end
