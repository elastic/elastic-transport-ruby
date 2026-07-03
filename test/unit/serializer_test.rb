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

class Elastic::Transport::Transport::SerializerTest < Minitest::Test

  context "Serializer" do

    should "use MultiJSON by default" do
      if defined?(::MultiJSON)
        ::MultiJSON.expects(:parse)
        ::MultiJSON.expects(:generate)
      else
        ::MultiJson.expects(:load)
        ::MultiJson.expects(:dump)
      end

      Elastic::Transport::Transport::Serializer::MultiJson.new.load('{}')
      Elastic::Transport::Transport::Serializer::MultiJson.new.dump({})
    end

    should "work when multi_json is loaded without RubyGems activation" do
      # When gems are loaded from a plain $LOAD_PATH (e.g. a `bundle install --standalone`
      # bundle or a vendored load path), they are not registered in Gem.loaded_specs.
      Gem.stubs(:loaded_specs).returns({})

      assert_equal({ 'foo' => 'bar' }, Elastic::Transport::Transport::Serializer::MultiJson.new.load('{"foo":"bar"}'))
      assert_equal('{"foo":"bar"}', Elastic::Transport::Transport::Serializer::MultiJson.new.dump({ 'foo' => 'bar' }))
    end

  end

end
