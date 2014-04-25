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
        :test_cmd => "bundle exec rspec --color --format progress spec/unit --tag ~graphviz && \
          bundle exec cucumber --color --format progress --tags ~@no_run --tags ~@spawn --tags ~@graphviz --strict"

      component "test-kitchen",
        :base_dir => "test-kitchen",
        :test_cmd => "bundle exec rake"

      component "chef-client",
        :base_dir => "chef",
        :test_cmd => "bundle exec rspec -fp spec/unit"

      component "chef-dk",
        :base_dir => "chef-dk",
        :test_cmd => "bundle exec rspec"

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
            result = system_command component_info[:test_cmd],
              :cwd => component_path(component_info),
              :env => {
                # Add the embedded/bin to the PATH so that bundle executable can
                # be found while running the tests.
                "PATH" => "#{bin_path}:#{ENV['PATH']}"
              },
              :timeout => 3600

            @verification_status = 1 if result.exitstatus != 0

            {
              :component => component,
              :result => result
            }
          end

          msg("Running verification for component '#{component}'")
        end
      end

      def wait_for_tests
        while !verification_threads.empty?
          verification_threads.each do |t|
            if t.join(1)
              verification_threads.delete t
              verification_results << t.value
              msg("")
              msg(t.value[:result].stdout)
              msg(t.value[:result].stderr) if t.value[:result].stderr
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
          message = result[:result].exitstatus == 0 ? "succeeded" : "failed"
          msg("Verification of component '#{result[:component]}' #{message}.")
        end
      end

    end
  end
end
