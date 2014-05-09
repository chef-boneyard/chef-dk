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

require 'spec_helper'
require 'chef-dk/command/verify'

describe ChefDK::Command::Verify do
  let(:command_instance) { ChefDK::Command::Verify.new() }

  let(:command_options) { [] }

  let(:components) { {} }

  def run_command(expected_exit_code)
    expect(command_instance.run(command_options)).to eq(expected_exit_code)
  end

  it "defines berks, tk, chef and chef-dk components by default" do
    expect(command_instance.components).not_to be_empty
    expect(command_instance.components.map(&:name)).to match_array(%w{berkshelf test-kitchen chef-client chef-dk})
  end

  it "has a usage banner" do
    expect(command_instance.banner).to eq("Usage: chef verify [component, ...] [options]")
  end

  describe "when locating omnibus directory" do
    it "should find omnibus app directory from ruby path" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby"))
      expect(command_instance.omnibus_apps_dir).to include("eg_omnibus_dir/valid/embedded")
    end

    it "should raise OmnibusInstallNotFound if directory is not looking like omnibus" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path,".rbenv/versions/2.1.1/bin/ruby"))
      expect{command_instance.omnibus_apps_dir}.to raise_error(ChefDK::Exceptions::OmnibusInstallNotFound)
    end

    it "raises OmnibusInstallNotFound if omnibus directory doesn't exist" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path,"eg_omnibus_dir/missing_apps/embedded/bin/ruby"))
      expect{command_instance.omnibus_apps_dir}.to raise_error(ChefDK::Exceptions::OmnibusInstallNotFound)
    end

    it "raises MissingComponentError when a component doesn't exist" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path,"eg_omnibus_dir/missing_component/embedded/bin/ruby"))
      expect{command_instance.validate_components!}.to raise_error(ChefDK::Exceptions::MissingComponentError)
    end
  end

  describe "defining components" do

    let(:command_class) { Class.new(ChefDK::Command::Verify) }

    let(:result) { {} }

    def define_component
      result_hash = result # so we can capture it in blocks
      command_class.add_component(:berks) do |c|
        c.base_dir = "berkshelf"
        c.unit_test { result_hash[:unit_test] = true }
        c.integration_test { result_hash[:integration_test] = true }
        c.smoke_test { result_hash[:smoke_test] = true }
      end
    end

    let(:component) do
      define_component
      command_class.component(:berks)
    end

    it "defines the component" do
      expect(component.name).to eq(:berks)
    end

    it "sets the component base directory" do
      expect(component.base_dir).to eq("berkshelf")
    end

    it "defines a unit test block" do
      component.run_unit_test
      expect(result[:unit_test]).to be_true
    end

    it "defines an integration test block" do
      component.run_integration_test
      expect(result[:integration_test]).to be_true
    end

    it "defines a smoke test block" do
      component.run_smoke_test
      expect(result[:smoke_test]).to be_true
    end

  end

  describe "when running verify command" do
    let(:stdout_io) { StringIO.new }
    let(:ruby_path) { File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby") }

    def stdout
      stdout_io.string
    end

    before do
      Gem.stub(:ruby).and_return(ruby_path)
      command_instance.stub(:stdout).and_return(stdout_io)
      command_instance.stub(:components).and_return(components)
    end

    context "when running smoke tests only" do
      describe "with single command with success" do
        let(:components) do
          [
            ChefDK::ComponentTest.new("successful_comp").tap do |c|
              # The verify_me script in chef exits non-zero, but our "smoke test" should succeed
              c.base_dir = "chef"
              c.unit_test { sh("./verify_me") }
              c.integration_test { sh("./integration_test") }
              c.smoke_test { sh("true") }
            end
          ]
        end

        before do
          run_command(0)
        end

        it "should report the success of the command" do
          expect(stdout).to include("Verification of component 'successful_comp' succeeded.")
        end

      end

      describe "with single command with failure" do
        let(:components) do
          [
            ChefDK::ComponentTest.new("failing_comp").tap do |c|
              # our fake berkshelf's unit tests succeed but our smoke test should fail
              c.base_dir = "berkshelf"
              c.unit_test { sh("./verify_me") }
              c.smoke_test { sh("false") }
            end
          ]
        end

        before do
          run_command(1)
        end

        it "should report the failure of the command" do
          expect(stdout).to include("Verification of component 'failing_comp' failed.")
        end

      end
    end

    context "when running unit tests" do

      let(:command_options) { %w{--unit --verbose} }

      let(:components) do
        [
          ChefDK::ComponentTest.new("successful_comp").tap do |c|
            c.base_dir = "berkshelf"
            c.unit_test { sh("./verify_me") }
            c.integration_test { sh("./integration_test") }
            c.smoke_test { sh("true") }
          end
        ]
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
              [
                ChefDK::ComponentTest.new("successful_comp").tap do |c|
                  c.base_dir = "berkshelf"
                  c.unit_test { sh("./verify_me") }
                  c.smoke_test { sh("true") }
                end
              ]
            end

            it "skips the integration test and succeeds" do
              expect(stdout).to include("Verification of component 'successful_comp' succeeded.")
            end

          end

        end

      end

      describe "with single command with failure" do
        let(:components) do
          [
            ChefDK::ComponentTest.new("failing_comp").tap do |c|
              c.base_dir = "chef"
              c.unit_test { sh("./verify_me") }
              c.smoke_test { sh("true") }
            end
          ]
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
          [
            ChefDK::ComponentTest.new("successful_comp_1").tap do |c|
              c.base_dir = "berkshelf"
              c.unit_test { sh("./verify_me") }
              c.smoke_test { sh("true") }
            end,

            ChefDK::ComponentTest.new("successful_comp_2").tap do |c|
              c.base_dir = "test-kitchen"
              c.unit_test { sh("./verify_me") }
              c.smoke_test { sh("true") }
            end
          ]
        end

        before do
          run_command(0)
        end

        it "should report the success of the command" do
          expect(stdout).to include("Verification of component 'successful_comp_1' succeeded.")
          expect(stdout).to include("Verification of component 'successful_comp_2' succeeded.")
        end

        it "reports the component test outputs" do
          expect(stdout).to include("you are good to go...")
          expect(stdout).to include("my friend everything is good...")
        end

        it "should report the output of the first verification first" do
          index_first = stdout.index("you are good to go...")
          index_second = stdout.index("my friend everything is good...")
          expect(index_second > index_first).to be_true
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
          [
            ChefDK::ComponentTest.new("successful_comp_1").tap do |c|
              c.base_dir = "berkshelf"
              c.unit_test { sh("./verify_me") }
              c.smoke_test { sh("true") }
            end,

            ChefDK::ComponentTest.new("successful_comp_2").tap do |c|
              c.base_dir = "test-kitchen"
              c.unit_test { sh("./verify_me") }
              c.smoke_test { sh("true") }
            end,

            ChefDK::ComponentTest.new("failing_comp").tap do |c|
              c.base_dir = "chef"
              c.unit_test { sh("./verify_me") }
              c.smoke_test { sh("true") }
            end
          ]
        end

        before do
          run_command(1)
        end

        it "should report the success and failure of the commands" do
          expect(stdout).to include("Verification of component 'successful_comp_1' succeeded.")
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
