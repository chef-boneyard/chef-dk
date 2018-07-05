#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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

require "chef-dk/command/base"
require "chef-dk/exceptions"
require "chef-dk/component_test"

module ChefDK
  module Command
    class Verify < ChefDK::Command::Base

      include ChefDK::Helpers

      banner "Usage: chef verify [component, ...] [options]"

      option :omnibus_dir,
        long: "--omnibus-dir OMNIBUS_DIR",
        description: "Alternate path to omnibus install (used for testing)"

      option :unit,
        long: "--unit",
        description: "Run bundled app unit tests (only smoke tests run by default)"

      option :integration,
        long: "--integration",
        description: "Run integration tests. Possibly dangerous, for development systems only"

      option :verbose,
        long: "--verbose",
        description: "Display all test output, not just failing tests"

      class << self
        def add_component(name, _delete_me = nil)
          component = ComponentTest.new(name)
          yield component if block_given? # delete this conditional
          component_map[name] = component
        end

        def component(name)
          component_map[name]
        end

        def components
          component_map.values
        end

        def component_map
          @component_map ||= {}
        end
      end

      def components
        self.class.components
      end

      bundle_install_mutex = Mutex.new

      #
      # Components included in Chef Development kit:
      # :base_dir => Relative path of the component w.r.t. omnibus_apps_dir
      # :gem_base_dir => Takes a gem name instead and uses first gem found
      # :test_cmd => Test command to be launched for the component
      #
      add_component "berkshelf" do |c|
        c.gem_base_dir = "berkshelf"
        # For berks the real command to run is "#{embedded_bin("bundle")} exec thor spec:ci"
        # We can't run it right now since graphviz specs are included in the
        # test suite by default. We will be able to switch to that command when/if
        # Graphviz is added to omnibus.
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec #{embedded_bin("rspec")} --color --format progress spec/unit --tag ~graphviz")
        end
        c.integration_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec #{embedded_bin("cucumber")} --color --format progress --tags ~@no_run --tags ~@spawn --tags ~@graphviz --strict")
        end

        c.smoke_test do
          tmpdir do |cwd|
            FileUtils.touch(File.join(cwd, "Berksfile"))
            sh("#{bin("berks")} install", cwd: cwd)
          end
        end
      end

      add_component "test-kitchen" do |c|
        c.gem_base_dir = "test-kitchen"
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec rake unit")
        end
        c.integration_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec rake features")
        end

        # NOTE: By default, kitchen tries to be helpful and install a driver
        # gem for you. This causes a race condition when running the tests
        # concurrently, because rubygems breaks when there are partially
        # installed gems in the gem repository. Instructing kitchen to create a
        # gemfile instead avoids the gem installation.
        c.smoke_test { run_in_tmpdir("kitchen init --create-gemfile") }
      end

      add_component "tk-policyfile-provisioner" do |c|

        c.gem_base_dir = "chef-dk"

        c.smoke_test do
          tmpdir do |cwd|
            File.open(File.join(cwd, ".kitchen.yml"), "w+") do |f|
              f.print(<<~KITCHEN_YML)
                ---
                driver:
                  name: dummy
                  network:
                    - ["forwarded_port", {guest: 80, host: 8080}]

                provisioner:
                  name: policyfile_zero
                  require_chef_omnibus: 12.3.0

                platforms:
                  - name: ubuntu-14.04

                suites:
                  - name: default
                    run_list:
                      - recipe[aar::default]
                    attributes:

              KITCHEN_YML
            end

            sh("kitchen list", cwd: cwd)

          end
        end

      end

      add_component "chef-client" do |c|
        c.gem_base_dir = "chef"
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec #{embedded_bin("rspec")} -fp -t '~volatile_from_verify' spec/unit")
        end
        c.integration_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec #{embedded_bin("rspec")} -fp spec/integration spec/functional")
        end

        c.smoke_test do
          tmpdir do |cwd|
            FileUtils.touch(File.join(cwd, "apply.rb"))
            sh("#{bin("chef-apply")} apply.rb", cwd: cwd)
          end
        end
      end

      add_component "chef-dk" do |c|
        c.gem_base_dir = "chef-dk"
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec #{embedded_bin("rspec")}")
        end
        c.smoke_test do
          run_in_tmpdir("#{bin("chef")} generate cookbook example")
        end
      end

      add_component "chef-apply" do |c|
        c.gem_base_dir = "chef-apply"
      #   c.unit_test do
      #     bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
      #     sh("#{embedded_bin("bundle")} exec rspec")
      #   end
        c.smoke_test { sh("#{bin("chef-run")} -v") }
      end

      add_component "chefspec" do |c|
        c.gem_base_dir = "chefspec"
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
          sh("#{embedded_bin("bundle")} exec #{embedded_bin("rake")} unit")
        end
        c.smoke_test do
          tmpdir do |cwd|
            FileUtils.mkdir(File.join(cwd, "spec"))
            with_file(File.join(cwd, "spec", "spec_helper.rb")) do |f|
              f.write <<~EOF
                require 'chefspec'
                require 'chefspec/berkshelf'
                require 'chefspec/cacher'

                RSpec.configure do |config|
                    config.expect_with(:rspec) { |c| c.syntax = :expect }
                end
              EOF
            end
            FileUtils.touch(File.join(cwd, "Berksfile"))
            with_file(File.join(cwd, "spec", "foo_spec.rb")) do |f|
              f.write <<~EOF
                require 'spec_helper'
              EOF
            end
            sh(embedded_bin("rspec"), cwd: cwd)
          end
        end
      end

      add_component "generated-cookbooks-pass-chefspec" do |c|

        c.gem_base_dir = "chef-dk"
        c.smoke_test do
          tmpdir do |cwd|
            sh("#{bin("chef")} generate cookbook example", cwd: cwd)
            cb_cwd = File.join(cwd, "example")
            sh(embedded_bin("rspec"), cwd: cb_cwd)
          end
        end
      end

      add_component "fauxhai" do |c|
        c.gem_base_dir = "fauxhai"
        c.smoke_test { sh("#{embedded_bin("gem")} list fauxhai") }
      end

      add_component "knife-spork" do |c|
        c.gem_base_dir = "knife-spork"
        c.smoke_test { sh("#{bin("knife")} spork info") }
      end

      add_component "kitchen-vagrant" do |c|
        c.gem_base_dir = "kitchen-vagrant"
        # The build is not passing in travis, so no tests
        c.smoke_test { sh("#{embedded_bin("gem")} list kitchen-vagrant") }
      end

      add_component "package installation" do |c|

        c.gem_base_dir = "chef-dk"

        c.smoke_test do

          if File.directory?(usr_bin_prefix)
            sh!("#{usr_bin_path("berks")} -v")
            sh!("#{usr_bin_path("chef")} -v")
            sh!("#{usr_bin_path("chef-client")} -v")
            sh!("#{usr_bin_path("chef-solo")} -v")
            sh!("#{usr_bin_path("delivery")} -V") unless Chef::Platform.windows?

            # In `knife`, `knife -v` follows a different code path that skips
            # command/plugin loading; `knife -h` loads commands and plugins, but
            # it exits with code 1, which is the same as a load error. Running
            # `knife exec` forces command loading to happen and this command
            # exits 0, which runs most of the code.
            #
            # See also: https://github.com/chef/chef-dk/issues/227
            sh!("#{usr_bin_path("knife")} exec -E true")

            tmpdir do |dir|
              # Kitchen tries to create a .kitchen dir even when just running
              # `kitchen -v`:
              sh!("#{usr_bin_path("kitchen")} -v", cwd: dir)
            end

            sh!("#{usr_bin_path("ohai")} -v")
            sh!("#{usr_bin_path("foodcritic")} -V")
            sh!("#{usr_bin_path("inspec")} version")
          end

          # Test blocks are expected to return a Mixlib::ShellOut compatible
          # object:
          ComponentTest::NullTestResult.new
        end
      end

      add_component "openssl" do |c|
        # https://github.com/chef/chef-dk/issues/420
        c.gem_base_dir = "chef"

        test = <<-EOF.gsub(/^\s+/, "")
        require "net/http"

        uris = %w{https://www.google.com https://chef.io/ https://ec2.amazonaws.com}
        uris.each do |uri|
          uri = URI(uri)
          puts "Fetching \#{uri} for SSL check"
          Net::HTTP.get uri
        end
        EOF

        c.unit_test do
          tmpdir do |cwd|
            with_file(File.join(cwd, "openssl.rb")) do |f|
              f.write test
            end
            sh!("#{Gem.ruby} openssl.rb", cwd: cwd)
          end
        end
      end

      add_component "inspec" do |c|
        c.gem_base_dir = "inspec"

        # Commenting out the unit and integration tests for now until we figure
        # out the bundler error
        # c.unit_test { sh("#{embedded_bin("bundle")} exec rake test:isolated") }
        # This runs Test Kitchen (using kitchen-inspec) with some inspec tests
        # c.integration_test { sh("#{embedded_bin("bundle")} exec rake test:vm") }

        # It would be nice to use a chef generator to create these specs, but
        # we dont have that yet.  So we do it manually.
        c.smoke_test do
          tmpdir do |cwd|
            File.open(File.join(cwd, "some_spec.rb"), "w+") do |f|
              f.print <<-INSPEC_TEST
                rule '01' do
                  impact 0.7
                  title 'Some Test'
                  desc 'Make sure inspec is installed and loading correct'
                  describe 1 do
                    it { should eq(1) }
                  end
                end
              INSPEC_TEST
            end
            # TODO when we appbundle inspec, no longer `chef exec`
            sh("#{bin("chef")} exec #{embedded_bin("inspec")} exec .", cwd: cwd)
          end
        end
      end

      add_component "delivery-cli" do |c|
        # We'll want to come back and revisit getting unit tests added -
        # currently running the tests depends on cargo , which is not included
        # in our package.
        c.base_dir = "bin"
        c.smoke_test do
          tmpdir do |cwd|
            sh!("delivery setup --user=shipit --server=delivery.shipit.io --ent=chef --org=squirrels", cwd: cwd)
          end
        end
      end

      if Chef::Platform.windows?
        add_component "git" do |c|
          c.base_dir = "embedded/bin"
          c.smoke_test do
            tmpdir do |cwd|
              sh!("#{embedded_bin("git")} config -l")
              sh!("#{embedded_bin("git")} clone https://github.com/chef/chef-provisioning", cwd: cwd)
            end
          end
        end
      else
        add_component "git" do |c|
          c.base_dir = "gitbin"
          c.smoke_test do
            tmpdir do |cwd|
              sh!("#{File.join(omnibus_root, "gitbin", "git")} config -l")
              sh!("#{File.join(omnibus_root, "gitbin", "git")} clone https://github.com/chef/chef-provisioning", cwd: cwd)

              # If /usr/bin/git is a symlink, fail the test.
              # Note that this test cannot go last because it does not return a
              # Mixlib::Shellout object in the windows case, which will break the tests.
              failure_str = "#{nix_platform_native_bin_dir}/git contains a symlink which might mean we accidentally overwrote system git via chefdk."
              result = sh("readlink #{nix_platform_native_bin_dir}/git")
              # if a symlink was found, test to see if it is in a chefdk install
              if result.status.exitstatus == 0
                raise failure_str if result.stdout =~ /chefdk/
              end

              # <chef_dk>/bin/ should not contain a git binary.
              failure_str = "`<chef_dk>/bin/git --help` should fail as git should be installed in gitbin"
              fail_if_exit_zero("#{bin("git")} --help", failure_str)
            end
          end
        end
      end

      add_component "opscode-pushy-client" do |c|
        c.gem_base_dir = "opscode-pushy-client"
        # TODO the unit tests are currently failing in master
        # c.unit_test do
        #   bundle_install_mutex.synchronize { sh("#{embedded_bin("bundle")} install") }
        #   sh("#{embedded_bin("bundle")} exec rake spec")
        # end

        c.smoke_test do
          tmpdir do |cwd|
            sh("#{bin("pushy-client")} -v", cwd: cwd)
          end
        end
      end

      # We try and use some chef-sugar code to make sure it loads correctly
      add_component "chef-sugar" do |c|
        c.gem_base_dir = "chef-sugar"
        c.smoke_test do
          tmpdir do |cwd|
            with_file(File.join(cwd, "foo.rb")) do |f|
              f.write <<~EOF
                require 'chef/sugar'
                log 'something' do
                  not_if  { _64_bit? }
                end
              EOF
            end
            sh("chef-apply foo.rb", cwd: cwd)
          end
        end
      end

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
        err("[WARN] This is an internal command used by the ChefDK development team. If you are a ChefDK user, please do not run it.")
        @components_filter = parse_options(params)

        validate_components!
        invoke_tests
        wait_for_tests
        report_results

        verification_status
      end

      def omnibus_root
        config[:omnibus_dir] || super
      end

      def validate_components!
        components.each do |component|
          component.omnibus_root = omnibus_root
          component.assert_present!
        end
      end

      def components_to_test
        if @components_filter.empty?
          components
        else
          components.select do |component|
            @components_filter.include?(component.name.to_s)
          end
        end
      end

      def invoke_tests
        components_to_test.each do |component|
          # Run the component specs in parallel
          verification_threads << Thread.new do

            results = []

            results << component.run_smoke_test

            if config[:unit]
              results << component.run_unit_test
            end

            if config[:integration]
              results << component.run_integration_test
            end

            if results.any? { |r| r.exitstatus != 0 }
              component_status = 1
              @verification_status = 1
            else
              component_status = 0
            end

            {
              component: component,
              results: results,
              component_status: component_status,
            }
          end

          msg("Running verification for component '#{component.name}'")
        end
      end

      def wait_for_tests
        until verification_threads.empty?
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
          msg("Verification of component '#{result[:component].name}' #{message}.")
        end
      end

    end
  end
end
