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
      DEFAULT_BODY_STRATEGY = 'omit'
      ENV_VARIABLE_ENABLED = 'OTEL_RUBY_INSTRUMENTATION_ELASTICSEARCH_ENABLED'
      ENV_VARIABLE_BODY_STRATEGY = 'OTEL_RUBY_INSTRUMENTATION_ELASTICSEARCH_BODY'
      ENV_VARIABLE_BODY_SANITIZE_KEYS = 'OTEL_RUBY_INSTRUMENTATION_ELASTICSEARCH_BODY_SANITIZE_KEYS'
      SEARCH_ENDPOINTS = Set[
        "search",
        "async_search.submit",
        "msearch",
        "eql.search",
        "terms_enum",
        "search_template",
        "msearch_template",
        "render_search_template",
      ]
      MUTEX = Mutex.new

      def initialize(opts)
        @tracer = (opts[:opentelemetry_tracer_provider] || ::OpenTelemetry.tracer_provider).tracer(
          OTEL_TRACER_NAME, Elastic::Transport::VERSION
        )
        @body_strategy = ENV[ENV_VARIABLE_BODY_STRATEGY] || DEFAULT_BODY_STRATEGY
        @sanitize_keys = ENV[ENV_VARIABLE_BODY_SANITIZE_KEYS]&.split(',')&.collect! do |pattern|
          Regexp.new(pattern.gsub('*', '.*'))
        end
      end
      attr_accessor :tracer

      def path_params(endpoint, path_templates, path)
        return unless endpoint && path_templates
        matching_regexp = path_regexps(endpoint, path_templates).find do |r|
          path.match?(r)
        end

        path.match(matching_regexp)&.named_captures if matching_regexp
      end

      def process_body(body, endpoint)
        unless @body_strategy == 'omit' || !SEARCH_ENDPOINTS.include?(endpoint)
          if @body_strategy == 'sanitize'
            body = Sanitizer.sanitize(body, @sanitize_keys)
          end
          body.to_json unless body&.is_a?(String)
        end
      end

      def path_regexps(endpoint, path_templates)
        return ENDPOINT_PATH_REGEXPS[endpoint] if ENDPOINT_PATH_REGEXPS.key?(endpoint)

        MUTEX.synchronize do
          return ENDPOINT_PATH_REGEXPS[endpoint] if ENDPOINT_PATH_REGEXPS.key?(endpoint)

          ENDPOINT_PATH_REGEXPS[endpoint] = path_templates.collect do |template|
            Regexp.new('^' + template.gsub('{', '(?<').gsub('}', '>[^/]+)') + '$')
          end
        end
        ENDPOINT_PATH_REGEXPS[endpoint]
      end

      # Replaces values in a hash, given a set of keys to match on.
      class Sanitizer
        class << self
          FILTERED = 'REDACTED'
          DEFAULT_KEY_PATTERNS =
            %w[password passwd pwd secret *key *token* *session* *credit* *card* *auth* set-cookie].map! do |p|
              Regexp.new(p.gsub('*', '.*'))
            end

          def sanitize(body, key_patterns = [])
            patterns = DEFAULT_KEY_PATTERNS
            patterns += key_patterns if key_patterns
            sanitize!(DeepDup.dup(body), patterns)
          end

          private

          def sanitize!(obj, key_patterns)
            return obj unless obj.is_a?(Hash)

            obj.each_pair do |k, v|
              if filter_key?(key_patterns, k)
                obj[k] = FILTERED
              elsif v.is_a?(Hash)
                sanitize!(v, key_patterns)
              else
                next
              end
            end
          end

          def filter_key?(key_patterns, key)
            key_patterns.any? { |regex| regex.match(key) }
          end
        end
      end

      # Makes a deep copy of an Array or Hash
      # NB: Not guaranteed to work well with complex objects, only simple Hash,
      # Array, String, Number, etc.
      class DeepDup
        def initialize(obj)
          @obj = obj
        end

        def dup
          deep_dup(@obj)
        end

        def self.dup(obj)
          new(obj).dup
        end

        private

        def deep_dup(obj)
          case obj
          when Hash then hash(obj)
          when Array then array(obj)
          else obj.dup
          end
        end

        def array(arr)
          arr.map { |obj| deep_dup(obj) }
        end

        def hash(hsh)
          result = hsh.dup

          hsh.each_pair do |key, value|
            result[key] = deep_dup(value)
          end

          result
        end
      end
    end
  end
end
