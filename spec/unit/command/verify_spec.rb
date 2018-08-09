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

require "spec_helper"
require "chef-dk/command/verify"

module Gem

  # We stub Gem.ruby because `verify` uses it to locate the omnibus directory,
  # but we also use it in some of the "test commands" in these tests.
  class << self
    alias :real_ruby :ruby
  end
end

describe ChefDK::Command::Verify do

  let(:command_instance) { ChefDK::Command::Verify.new() }

  let(:command_options) { [] }

  let(:components) { {} }

  let(:default_components) do
    [
      "berkshelf",
      "test-kitchen",
      "tk-policyfile-provisioner",
      "chef-client",
      "chef-dk",
      "chef-apply",
      "chef-provisioning",
      "chefspec",
      "generated-cookbooks-pass-chefspec",
      "fauxhai",
      "knife-spork",
      "kitchen-vagrant",
      "package installation",
      "openssl",
      "inspec",
      "chef-sugar",
      "opscode-pushy-client",
      "git",
      "delivery-cli",
    ]
  end

  def run_command(expected_exit_code)
    expect(command_instance.run(command_options)).to eq(expected_exit_code)
  end

  it "defines berks, tk, chef and chef-dk components by default" do
    expected_components = default_components
    expect(command_instance.components).not_to be_empty
    expect(command_instance.components.map(&:name)).to match_array(expected_components)
  end

  it "has a usage banner" do
    expect(command_instance.banner).to eq("Usage: chef verify [component, ...] [options]")
  end

  describe "when locating omnibus directory" do
    it "should find omnibus app directory from ruby path" do
      allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby"))
      expect(command_instance.omnibus_apps_dir).to include("eg_omnibus_dir/valid/embedded")
    end

    it "should raise OmnibusInstallNotFound if directory is not looking like omnibus" do
      allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, ".rbenv/versions/2.1.1/bin/ruby"))
      expect { command_instance.omnibus_apps_dir }.to raise_error(ChefDK::OmnibusInstallNotFound)
    end

    it "raises OmnibusInstallNotFound if omnibus directory doesn't exist" do
      allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/missing_apps/embedded/bin/ruby"))
      expect { command_instance.omnibus_apps_dir }.to raise_error(ChefDK::OmnibusInstallNotFound)
    end

    context "and a component's gem is not installed" do
      before do
        component_map = ChefDK::Command::Verify.component_map.dup
        component_map["cucumber"] = ChefDK::ComponentTest.new("cucumber")
        component_map["cucumber"].gem_base_dir = "cucumber"
        allow(ChefDK::Command::Verify).to receive(:component_map).and_return(component_map)
      end

      it "raises MissingComponentError when a component doesn't exist" do
        allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/missing_component/embedded/bin/ruby"))
        expect { command_instance.validate_components! }.to raise_error(ChefDK::MissingComponentError)
      end
    end
  end

  describe "when running verify command" do
    let(:stdout_io) { StringIO.new }
    let(:stderr_io) { StringIO.new }
    let(:ruby_path) { File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby") }

    def run_unit_test
      # Set rubyopt to empty to prevent bundler from infecting the ruby
      # subcommands (and loading a bunch of extra gems).
      lambda { |_self| sh("#{Gem.real_ruby} verify_me", env: { "RUBYOPT" => "" }) }
    end

    def run_integration_test
      lambda { |_self| sh("#{Gem.real_ruby} integration_test", env: { "RUBYOPT" => "" }) }
    end

    let(:all_tests_ok) do
      ChefDK::ComponentTest.new("successful_comp").tap do |c|
        c.base_dir = "embedded/apps/berkshelf"
        c.unit_test(&run_unit_test)
        c.integration_test(&run_integration_test)
        c.smoke_test { sh("exit 0") }
      end
    end

    let(:all_tests_ok_2) do
      ChefDK::ComponentTest.new("successful_comp_2").tap do |c|
        c.base_dir = "embedded/apps/test-kitchen"
        c.unit_test(&run_unit_test)
        c.smoke_test { sh("exit 0") }
      end
    end

    let(:failing_unit_test) do
      ChefDK::ComponentTest.new("failing_comp").tap do |c|
        c.base_dir = "embedded/apps/chef"
        c.unit_test(&run_unit_test)
        c.smoke_test { sh("exit 0") }
      end
    end

    let(:passing_smoke_test_only) do
      component = failing_unit_test.dup
      component.smoke_test { sh("exit 0") }
      component
    end

    let(:failing_smoke_test_only) do
      component = all_tests_ok.dup
      component.smoke_test { sh("exit 1") }
      component
    end

    let(:component_without_integration_tests) do
      ChefDK::ComponentTest.new("successful_comp").tap do |c|
        c.base_dir = "embedded/apps/berkshelf"
        c.unit_test { sh("./verify_me") }
        c.smoke_test { sh("exit 0") }
      end
    end

    def stdout
      stdout_io.string
    end

    before do
      allow(Gem).to receive(:ruby).and_return(ruby_path)
      allow(command_instance).to receive(:stdout).and_return(stdout_io)
      allow(command_instance).to receive(:stderr).and_return(stderr_io)
      allow(command_instance).to receive(:components).and_return(components)
    end

    context "when running smoke tests only" do
      describe "with single command with success" do
        let(:components) do
          [ passing_smoke_test_only ]
        end

        before do
          run_command(0)
        end

        it "should report the success of the command" do
          expect(stdout).to include("Verification of component 'failing_comp' succeeded.")
        end

      end

      describe "with single command with failure" do
        let(:components) do
          [ failing_smoke_test_only ]
        end

        before do
          run_command(1)
        end

        it "should report the failure of the command" do
          expect(stdout).to include("Verification of component 'successful_comp' failed.")
        end

      end
    end

    context "when running unit tests" do

      let(:command_options) { %w{--unit --verbose} }

      let(:components) do
        [ all_tests_ok ]
      end

      describe "with single command with success" do
        before do
          run_command(0)
        end

        it "should have embedded/bin on the PATH" do
          expect(stdout).to include(File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin"))
        end

        it "should report the success of the command" do
          expect(stdout).to include("Verification of component 'successful_comp' succeeded.")
        end

        it "reports the component test output" do
          expect(stdout).to include("you are good to go...")
        end

        context "and --verbose is not enabled" do

          let(:command_options) { %w{--unit} }

          it "omits the component test output" do
            expect(stdout).to_not include("you are good to go...")
          end
        end

        context "and --integration flag is given" do

          let(:command_options) { %w{--integration --verbose} }

          it "should run the integration command also" do
            expect(stdout).to include("integration tests OK")
          end

          context "and no integration test command is specifed for the component" do

            let(:components) do
              [ component_without_integration_tests ]
            end

            it "skips the integration test and succeeds" do
              expect(stdout).to include("Verification of component 'successful_comp' succeeded.")
            end

          end

        end

      end

      describe "with single command with failure" do
        let(:components) do
          [ failing_unit_test ]
        end

        before do
          run_command(1)
        end

        it "should report the failure of the command" do
          expect(stdout).to include("Verification of component 'failing_comp' failed.")
        end

        it "reports the component test output" do
          expect(stdout).to include("i'm not feeling good today...")
        end
      end

      describe "with multiple commands with success" do
        let(:components) do
          [ all_tests_ok, all_tests_ok_2 ]
        end

        before do
          run_command(0)
        end

        it "should report the success of the command" do
          expect(stdout).to include("Verification of component 'successful_comp' succeeded.")
          expect(stdout).to include("Verification of component 'successful_comp_2' succeeded.")
        end

        it "reports the component test outputs" do
          expect(stdout).to include("you are good to go...")
          expect(stdout).to include("my friend everything is good...")
        end

        context "and components are filtered by CLI args" do

          let(:command_options) { [ "successful_comp_2" ] }

          it "verifies only the desired component" do
            expect(stdout).to_not include("Verification of component 'successful_comp_1' succeeded.")
            expect(stdout).to include("Verification of component 'successful_comp_2' succeeded.")
          end

        end
      end

      describe "with multiple commands with failures" do
        let(:components) do
          [ all_tests_ok, all_tests_ok_2, failing_unit_test ]
        end

        before do
          run_command(1)
        end

        it "should report the success and failure of the commands" do
          expect(stdout).to include("Verification of component 'successful_comp' succeeded.")
          expect(stdout).to include("Verification of component 'successful_comp_2' succeeded.")
          expect(stdout).to include("Verification of component 'failing_comp' failed.")
        end

        it "reports the component test outputs" do
          expect(stdout).to include("you are good to go...")
          expect(stdout).to include("my friend everything is good...")
          expect(stdout).to include("i'm not feeling good today...")
        end
      end

    end
  end

end
