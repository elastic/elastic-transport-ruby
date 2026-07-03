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
        # An abstract class for implementing serializer implementations
        #
        module Base
          # @param transport [Object] The instance of transport which uses this serializer
          #
          def initialize(transport = nil)
            @transport = transport
          end
        end

        # A default JSON serializer (using [MultiJSON](http://rubygems.org/gems/multi_json))
        #
        class MultiJson
          include Base

          # De-serialize a Hash from JSON string
          #
          def load(string, options = {})
            if deprecated_gem_version_loaded?
              ::MultiJson.load(string, options)
            else
              ::MultiJSON.parse(string, options)
            end
          end

          # Serialize a Hash to JSON string
          #
          def dump(object, options = {})
            if deprecated_gem_version_loaded?
              ::MultiJson.dump(object, options)
            else
              ::MultiJSON.generate(object, options)
            end
          end

          private

          # multi_json 1.21.0 renamed the top-level constant to `MultiJSON` (keeping a
          # deprecated `MultiJson` alias), so the constant's absence indicates a deprecated
          # version. Checking the constant rather than `Gem.loaded_specs` also works when
          # the gem is loaded without RubyGems activation (e.g. from a `bundle install
          # --standalone` bundle or a vendored load path), where `Gem.loaded_specs` is
          # empty and the version lookup would raise a `NoMethodError` on `nil`.
          def deprecated_gem_version_loaded?
            !defined?(::MultiJSON)
          end
        end
      end
    end
  end
end
