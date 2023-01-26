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

require 'bundler/gem_tasks'
require 'mkmf'

desc 'Run unit tests'
task default: 'test:unit'
task test: 'test:unit'

# ----- Test tasks ------------------------------------------------------------
require 'rake/testtask'
require 'rspec/core/rake_task'
FARADAY1_GEMFILE = 'Gemfile-faraday1.gemfile'.freeze
GEMFILES = ['Gemfile', FARADAY1_GEMFILE].freeze

task :install do
  GEMFILES.each do |gemfile|
    gemfile = File.expand_path("../#{gemfile}", __FILE__)
    sh "bundle install --gemfile #{gemfile}"
  end
end

namespace :test do
  RSpec::Core::RakeTask.new(:spec)

  Rake::TestTask.new(:unit) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList['test/unit/**/*_test.rb']
    test.verbose = false
    test.warning = false
  end

  Rake::TestTask.new(:integration) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList['test/integration/**/*_test.rb']
    test.verbose = false
    test.warning = false
  end

  desc 'Run all tests'
  task :all do
    Rake::Task['test:unit'].invoke
    Rake::Task['test:spec'].invoke
    Rake::Task['test:integration'].invoke
  end

  Rake::TestTask.new(:profile) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList['test/profile/**/*_test.rb']
  end

  namespace :faraday1 do
    desc 'Faraday 1: Run RSpec with dependency on Faraday 1'
    task :spec do
      sh "BUNDLE_GEMFILE=#{FARADAY1_GEMFILE} bundle exec rspec"
    end

    desc 'Faraday 1: Run unit tests with dependency on Faraday 1'
    task :unit do
      Dir.glob('./test/unit/**/**.rb').each do |test|
        sh "BUNDLE_GEMFILE=#{FARADAY1_GEMFILE} ruby -Ilib:test #{test}"
      end
    end

    desc 'Faraday 1: Run integration tests with dependency on Faraday 1'
    task :integration do
      Dir.glob('./test/integration/**/**.rb').each do |test|
        sh "BUNDLE_GEMFILE=#{FARADAY1_GEMFILE} ruby -Ilib:test #{test}"
      end
    end

    desc 'Faraday 1: Run all tests'
    task :all do
      Rake::Task['test:faraday1:unit'].invoke
      Rake::Task['test:faraday1:spec'].invoke
      Rake::Task['test:faraday1:integration'].invoke
    end
  end
end

namespace :docker do
  desc <<~DOC
    Start Elasticsearch in a Docker container. Credentials are 'elastic:changeme'.

    Default:
      rake docker:start[version]
    E.g.:
      rake docker:start[8.0.0-SNAPSHOT]
  DOC
  task :start, [:version] do |_, params|
    abort 'Docker not installed' unless find_executable 'docker'
    abort 'You need to set a version, e.g. rake docker:start[7.x-SNAPSHOT]' unless params[:version]

    system("docker run -p 9200:9200 -p 9300:9300 -e 'discovery.type=single-node' -e ELASTIC_PASSWORD=changeme docker.elastic.co/elasticsearch/elasticsearch:#{params[:version]}")
  end
end

desc 'Run Ruby console with the Elastic transport client libraries loaded'
task :console do
  require 'irb'
  require 'irb/completion'
  require 'elastic-transport'
  ARGV.clear
  IRB.start
end

# ----- Documentation tasks ---------------------------------------------------
require 'yard'
YARD::Rake::YardocTask.new(:doc) do |t|
  t.options = %w| --embed-mixins --markup=markdown |
end

# ----- Code analysis tasks ---------------------------------------------------
require 'cane/rake_task'
Cane::RakeTask.new(:quality) do |cane|
  cane.abc_max = 15
  cane.no_style = true
end
