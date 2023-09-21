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
require 'uri'

password = ENV['ELASTIC_PASSWORD'] || 'changeme'
host = ENV['TEST_ES_SERVER'] || 'http://localhost:9200'
raise URI::InvalidURIError unless host =~ /\A#{URI::DEFAULT_PARSER.make_regexp}\z/

uri = URI.parse(host)
HOST = "http://elastic:#{password}@#{uri.host}:#{uri.port}".freeze

JRUBY = defined?(JRUBY_VERSION)

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start { add_filter %r{^/test/} }
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'shoulda/context'

require 'elastic-transport'
require 'hashie'
require 'logger'
require 'require-prof' if ENV["REQUIRE_PROF"]

RequireProf.print_timing_infos if ENV["REQUIRE_PROF"]

class FixedMinitestSpecReporter < Minitest::Reporters::SpecReporter
  def before_test(test)
    last_test = tests.last

    before_suite(test.class) unless last_test

    if last_test && last_test.klass.to_s != test.class.to_s
      after_suite(last_test.class) if last_test
      before_suite(test.class)
    end
  end
end

module Minitest
  class Test
    def assert_nothing_raised(*args)
      begin
        yield
      rescue RuntimeError => e
        raise MiniTest::Assertion, "Exception raised:\n<#{e.class}>", e.backtrace
      end
      true
    end

    def assert_not_nil(object, msg=nil)
      msg = message(msg) { "<#{object.inspect}> expected to not be nil" }
      assert !object.nil?, msg
    end

    def assert_block(*msgs)
      assert yield, *msgs
    end

    alias :assert_raise :assert_raises
  end
end

def is_faraday_v2?
  Gem::Version.new(Faraday::VERSION) >= Gem::Version.new(2)
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new(print_failure_summary: true)
