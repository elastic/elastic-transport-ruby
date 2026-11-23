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
    module Transport
      module Serializer
        class Json
          include Base

          # De-serialize a Hash from JSON string
          #
          def load(string, options = {})
            if string.encoding != Encoding::UTF_8
              string = string.dup.force_encoding(Encoding::UTF_8)
              raise ::JSON::ParserError, "Invalid UTF-8 byte sequence in JSON input" unless string.valid_encoding?
            end

            ::JSON.parse(string, **options)
          end

          # Serialize a Hash to JSON string
          #
          def dump(object, options = {})
            json_object = object.respond_to?(:as_json) ? object.as_json : object
            return ::JSON.dump(json_object) if options.empty?
            return ::JSON.generate(json_object, options) unless options.key?(:pretty)

            # ``:pretty`` is MultiJSON's own option, not one the JSON gem's
            # generator understands, so it's stripped rather than passed
            # through. A falsy value asks for compact output, which is what
            # the generator produces with no pretty state at all.
            rest = options.except(:pretty)
            return generate_compact(json_object, rest) unless options[:pretty]

            # Common case: ``pretty: true`` is the only option, so the merge
            # would just produce a copy of PRETTY_STATE_PROTOTYPE.
            return ::JSON.pretty_generate(json_object, PRETTY_STATE_PROTOTYPE) if rest.empty?

            ::JSON.pretty_generate(json_object, PRETTY_STATE_PROTOTYPE.merge(rest))
          end

          private

          def deprecated_gem_version_loaded?
            Gem.loaded_specs['multi_json'].version < Gem::Version.create('1.21.0')
          end
        end
      end
    end
  end
end
