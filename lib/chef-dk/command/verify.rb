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
require 'chef-dk/component_test'

module ChefDK
  module Command
    class Verify < ChefDK::Command::Base

      include ChefDK::Helpers

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
        def add_component(name, _delete_me=nil)
          component = ComponentTest.new(name)
          yield component if block_given? #delete this conditional
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
        # For berks the real command to run is "#{bin("bundle")} exec thor spec:ci"
        # We can't run it right now since graphviz specs are included in the
        # test suite by default. We will be able to switch to that command when/if
        # Graphviz is added to omnibus.
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec #{bin("rspec")} --color --format progress spec/unit --tag ~graphviz")
        end
        c.integration_test do
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec #{bin("cucumber")} --color --format progress --tags ~@no_run --tags ~@spawn --tags ~@graphviz --strict")
        end

        c.smoke_test do
          tmpdir do |cwd|
            FileUtils.touch(File.join(cwd,"Berksfile"))
            sh("#{bin("berks")} install", cwd: cwd)
          end
        end
      end

      add_component "test-kitchen" do |c|
        c.gem_base_dir = "test-kitchen"
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec rake unit")
        end
        c.integration_test do
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec rake features")
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
              f.print(<<-KITCHEN_YML)
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
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec #{bin("rspec")} -fp -t '~volatile_from_verify' spec/unit")
        end
        c.integration_test do
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec #{bin("rspec")} -fp spec/integration spec/functional")
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
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec #{bin("rspec")}")
        end
        c.smoke_test do
          run_in_tmpdir("#{bin("chef")} generate cookbook example")
        end
      end

      # entirely possible this needs to be driven by a utility method in chef-provisioning.
      add_component "chef-provisioning" do |c|
        c.gem_base_dir = "chef-dk"

        c.smoke_test do
          # ------------
          # we want to avoid hard-coding driver names, but calling Gem::Specification produces a warning;
          # changing $VERBOSE seems to be the best way to silence it.
          verbose = $VERBOSE
          $VERBOSE = nil

          # construct a hash of { driver_name => [version1, version2, ...]}
          driver_versions = {}
          Gem::Specification.all.map { |gs| [gs.name, gs.version] }.
                                  select { |n| n[0] =~ /^chef-provisioning-/ }.
                                  each { |gem, version| (driver_versions[gem] ||= []) << version }

          drivers = Gem::Specification.all.map { |gs| gs.name }.
                                           select { |n| n =~ /^chef-provisioning-/ }.
                                           uniq

          versions = Gem::Specification.find_all_by_name("chef-provisioning").map { |s| s.version }
          $VERBOSE = verbose
          # ------------
          failures = []

          # ------------
          # fail the verify if we have more than one version of chef-provisioning or any of its drivers.
          def format_gem_failure(name, versions)
            <<-EOS
#{name} has multiple versions installed:
#{versions.sort.map { |gv| "    #{gv.to_s}" }.join("\n")}
            EOS
          end

          failures << format_gem_failure("chef-provisioning", versions) if versions.size > 1

          driver_versions.keys.sort.each do |driver_name|
            v = driver_versions[driver_name]
            failures << format_gem_failure(driver_name, v) if v.size > 1
          end

          if failures.size > 0
            failures << <<-EOS

Some applications may need or prefer different versions of the chef-provisioning gem or its drivers, so
this multiple-version check can fail if a user has installed new versions of those libraries.
EOS
          end

          # ------------
          # load the core gem and all of the drivers (ignoring versions).
          require "chef/provisioning"
          drivers.map { |d| "#{d.gsub('-', '/')}_driver" }.each do |driver_gem|
            begin
              begin
                require driver_gem
              rescue LoadError
                # anomalously, chef-provisioning-fog does not have a fog_driver.rb. (9/2015)
                require "#{driver_gem}/driver.rb"
              end
            rescue LoadError => ex
              puts ex
            end
          end

          # ------------
          # look for version dependency conflicts.
          tmpdir do |cwd|
            versions.each do |provisioning_version|
              gemfile = "chef-provisioning-#{provisioning_version}-chefdk-test.gemfile"

              # write out the gemfile for this chef-provisioning version, and see if Bundler can make it go.
              with_file(File.join(cwd, gemfile)) do |f|
                f.puts %Q(gem "chef-provisioning", "= #{provisioning_version}")
                drivers.each { |d| f.puts %Q(gem "#{d}") }
              end

              result = bundle_install_mutex.synchronize do
                sh("#{bin("bundle")} install --local --quiet", cwd: cwd, env: {"BUNDLE_GEMFILE" => gemfile })
              end

              if result.exitstatus != 0
                failures << result.stdout
              end
            end  # end provisioning versions.

            failures.each { |fail| puts fail }

            # dubious on Windows.
            # this is weird, but we seem to require a Mixlib::ShellOut as the return value. suggestions
            # welcome.
            sh(failures.size > 0 ? "false" : "true")
          end
        end
      end


      add_component "chefspec" do |c|
        c.gem_base_dir = "chefspec"
        c.unit_test do
          bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
          sh("#{bin("bundle")} exec #{bin("rake")} unit")
        end
        c.smoke_test do
          tmpdir do |cwd|
            FileUtils.mkdir(File.join(cwd, "spec"))
            with_file(File.join(cwd, "spec", "spec_helper.rb")) do |f|
              f.write <<-EOF
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
              f.write <<-EOF
require 'spec_helper'
              EOF
            end
            sh(bin("rspec"), cwd: cwd)
          end
        end
      end

      add_component "generated-cookbooks-pass-chefspec" do |c|

        c.gem_base_dir = "chef-dk"
        c.smoke_test do
          tmpdir do |cwd|
            sh("#{bin("chef")} generate cookbook example", cwd: cwd)
            cb_cwd = File.join(cwd, "example")
            sh(bin("rspec"), cwd: cb_cwd)
          end
        end
      end

      add_component "rubocop" do |c|
        c.gem_base_dir = "rubocop"
        c.smoke_test do
          tmpdir do |cwd|
            with_file(File.join(cwd, 'foo.rb')) do |f|
              f.write <<-EOF
def foo
  puts 'foo'
end
              EOF
            end
            sh("#{bin("rubocop")} foo.rb -l", cwd: cwd)
          end
        end
      end

      add_component "fauxhai" do |c|
        c.gem_base_dir = "fauxhai"
        c.smoke_test { sh("#{bin("gem")} list fauxhai") }
      end

      add_component "knife-spork" do |c|
        c.gem_base_dir = "knife-spork"
        c.smoke_test { sh("#{bin("knife")} spork info")}
      end

      add_component "kitchen-vagrant" do |c|
        c.gem_base_dir = "kitchen-vagrant"
        # The build is not passing in travis, so no tests
        c.smoke_test { sh("#{bin("gem")} list kitchen-vagrant") }
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
        #c.unit_test { sh("#{bin("bundle")} exec rake test:isolated") }
        # This runs Test Kitchen (using kitchen-inspec) with some inspec tests
        #c.integration_test { sh("#{bin("bundle")} exec rake test:vm") }

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
            sh("#{bin("chef")} exec #{bin("inspec")} exec .", cwd: cwd)
          end
        end
      end

      unless Chef::Platform.windows?
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
      end

      if Chef::Platform.windows?
        # TODO UW-6 - We haven't decided exactly where these binaries will live
        # so we will write this test when we do this card
        # add_component "git-windows"
      else
        add_component "git" do |c|
          c.base_dir = "embedded/bin"
          c.smoke_test do
            sh!("#{embedded_bin("git")} config -l")
          end
          c.integration_test do
            tmpdir do |cwd|
              sh!("#{embedded_bin("git")} clone git@github.com:chef/ffi-yajl.git", cwd: cwd)
              sh!("#{embedded_bin("git")} clone https://github.com/chef/chef-provisioning", cwd: cwd)
            end
          end
        end
      end

      add_component "opscode-pushy-client" do |c|
        c.gem_base_dir = "opscode-pushy-client"
        # TODO the unit tests are currently failing in master
        # c.unit_test do
        #   bundle_install_mutex.synchronize { sh("#{bin("bundle")} install") }
        #   sh("#{bin("bundle")} exec rake spec")
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
            with_file(File.join(cwd, 'foo.rb')) do |f|
              f.write <<-EOF
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

      add_component "knife-supermarket" do |c|
        c.gem_base_dir = "knife-supermarket"
        c.smoke_test { sh("#{bin("knife")} supermarket search httpd")}
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

          msg("Running verification for component '#{component.name}'")
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
          msg("Verification of component '#{result[:component].name}' #{message}.")
        end
      end

    end
  end
end
