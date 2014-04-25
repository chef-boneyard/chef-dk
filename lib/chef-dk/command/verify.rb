#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef-dk/command/base'
require 'chef-dk/exceptions'

module ChefDK
  module Command
    class Verify < ChefDK::Command::Base
      include ChefDK::Exceptions

      banner "Usage: chef verify [component, ...] [options]"

      option :omnibus_dir,
        :long         => "--omnibus-dir OMNIBUS_DIR",
        :description  => "Alternate path to omnibus install (used for testing)"

      option :unit,
        :long         => "--unit",
        :description  => "Run bundled app unit tests (only smoke tests run by default)"

      option :integration,
        :long         => "--integration",
        :description  => "Run integration tests. Possibly dangerous, for development systems only"

      option :verbose,
        :long         => "--verbose",
        :description  => "Display all test output, not just failing tests"

      class << self
        def component(name, arguments)
          components[name] = arguments
        end

        def components
          @components ||= {}
          @components
        end
      end

      def components
        self.class.components
      end

      #
      # Components included in Chef Development kit:
      # :base_dir => Relative path of the component w.r.t. #{omnibus_dir}/apps
      # :test_cmd => Test command to be launched for the component
      #
      component "berkshelf",
        :base_dir => "berkshelf",
        # For berks the real command to run is "bundle exec thor spec:ci"
        # We can't run it right now since graphviz specs are included in the
        # test suite by default. We will be able to switch to that command when/if
        # Graphviz is added to omnibus.
        :test_cmd => "bundle exec rspec --color --format progress spec/unit --tag ~graphviz",
        :integration_cmd => "bundle exec cucumber --color --format progress --tags ~@no_run --tags ~@spawn --tags ~@graphviz --strict",
        :smoke => "touch Berksfile; berks install"

      component "test-kitchen",
        :base_dir => "test-kitchen",
        :test_cmd => "bundle exec rake unit",
        :integration_cmd => "bundle exec rake features",
        :smoke => "kitchen init"

      component "chef-client",
        :base_dir => "chef",
        :test_cmd => "bundle exec rspec -fp spec/unit",
        :integration_cmd => "bundle exec rspec -fp spec/integration spec/functional",
        :smoke => "touch apply.rb; chef-apply apply.rb"

      component "chef-dk",
        :base_dir => "chef-dk",
        :test_cmd => "bundle exec rspec",
        :smoke => "chef generate cookbook example"

      attr_reader :omnibus_dir
      attr_reader :verification_threads
      attr_reader :verification_results
      attr_reader :verification_status

      def initialize
        super
        @verification_threads = [ ]
        @verification_results = [ ]
        @verification_status = 0
      end

      def run(params = [ ])
        @components_filter = parse_options(params)
        @components_filter.unshift # remove 'verify' from the remaining args

        locate_omnibus_dir
        invoke_tests
        wait_for_tests
        report_results

        verification_status
      end

      #
      # Locates the directory components are installed on the system.
      #
      # In omnibus installations ruby lives at:
      # omnibus_install_dir/embedded/bin and components live at
      # omnibus_install_dir/embedded/apps
      #
      def locate_omnibus_dir
        @omnibus_dir = config[:omnibus_dir] || File.expand_path(File.join(Gem.ruby, "..","..", "apps"))

        raise OmnibusInstallNotFound.new() unless (omnibus_dir and File.directory?(omnibus_dir) )

        components.each do |component, component_info|
          unless File.exists? component_path(component_info)
            raise MissingComponentError.new(component)
          end
        end
      end

      def component_path(component_info)
        File.join(omnibus_dir, component_info[:base_dir])
      end

      def components_to_test
        if @components_filter.empty?
          components
        else
          components.select do |name, test_params|
            @components_filter.include?(name)
          end
        end
      end

      def invoke_tests
        components_to_test.each do |component, component_info|
          # Run the component specs in parallel
          verification_threads << Thread.new do
            bin_path = File.expand_path(File.join(omnibus_dir, "..", "bin"))

            test_cmd_opts = {
              :cwd => component_path(component_info),
              :env => {
                # Add the embedded/bin to the PATH so that bundle executable can
                # be found while running the tests.
                "PATH" => "#{bin_path}:#{ENV['PATH']}"
              },
              :timeout => 3600
            }

            results = []

            results << run_smoke_test(component_info[:smoke], test_cmd_opts)

            if config[:unit]
              results << system_command(component_info[:test_cmd], test_cmd_opts)
            end

            if config[:integration]
              results << system_command(component_info[:integration_cmd], test_cmd_opts)
            end

            if results.any? {|r| r.exitstatus != 0 }
              component_status = 1
              @verification_status = 1
            else
              component_status = 0
            end

            {
              :component => component,
              :results => results,
              :component_status => component_status
            }
          end

          msg("Running verification for component '#{component}'")
        end
      end

      def run_smoke_test(command, command_opts)
        command_opts = command_opts.dup
        Dir.mktmpdir do |tmpdir|
          command_opts[:cwd] = tmpdir
          system_command(command, command_opts)
        end
      end

      def wait_for_tests
        while !verification_threads.empty?
          verification_threads.each do |t|
            if t.join(1)
              verification_threads.delete t
              verification_results << t.value
              t.value[:results].each do |result|
                if config[:verbose] || t.value[:component_status] != 0
                  msg("")
                  msg(result.stdout)
                  msg(result.stderr) if result.stderr
                end
              end
            else
              $stdout.write "."
            end
          end
        end
      end

      def report_results
        msg("")
        msg("---------------------------------------------")
        verification_results.each do |result|
          message = result[:component_status] == 0 ? "succeeded" : "failed"
          msg("Verification of component '#{result[:component]}' #{message}.")
        end
      end

    end
  end
end
