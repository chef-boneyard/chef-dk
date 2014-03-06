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

  def run_command(expected_exit_code, command_options = [ ])
    expect(command_instance.run(command_options)).to eq(expected_exit_code)
  end

  describe "when locating omnibus directory" do
    it "should find omnibus directory from ruby path" do
      Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH, "eg_omnibus_dir/valid/embedded/bin/ruby"))
      command_instance.locate_omnibus_dir
      expect(command_instance.omnibus_dir).to include("eg_omnibus_dir/valid/embedded")
    end

    it "should raise OmnibusInstallNotFound if directory is not looking like omnibus" do
      Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH,".rbenv/versions/2.1.1/bin/ruby"))
      expect{command_instance.locate_omnibus_dir}.to raise_error(ChefDK::Exceptions::OmnibusInstallNotFound)
    end

    it "raises OmnibusInstallNotFound if omnibus directory doesn't exist" do
      Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH,"eg_omnibus_dir/missing_apps/embedded/bin/ruby"))
      expect{command_instance.locate_omnibus_dir}.to raise_error(ChefDK::Exceptions::OmnibusInstallNotFound)
    end

    it "raises MissingComponentError when a component doesn't exist" do
      Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH,"eg_omnibus_dir/missing_component/embedded/bin/ruby"))
      expect{command_instance.locate_omnibus_dir}.to raise_error(ChefDK::Exceptions::MissingComponentError)
    end
  end

  describe "when running verify command" do
    let(:stdout_io) { StringIO.new }

    def stdout
      stdout_io.string
    end

    before do
      command_instance.stub(:stdout).and_return(stdout_io)
    end

    it "should have components by default" do
      expect(command_instance.components).not_to be_empty
    end

    it "should have components by default" do
      expect(command_instance.banner).to eq("Usage: chef verify")
    end

    describe "with single command with success" do
      before do
        Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH, "eg_omnibus_dir/valid/embedded/bin/ruby"))
        command_instance.stub(:components).and_return({
          "successful_comp" => {
            :base_dir => "berkshelf",
            :test_cmd => "./verify_me"
          }
        })

        run_command(0)
      end

      it "should report the success of the command" do
        expect(stdout).to include("Verification of component 'successful_comp' succeeded.")
      end

      it "reports the component test output" do
        expect(stdout).to include("you are good to go...")
      end
    end

    describe "with single command with failure" do
      before do
        Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH, "eg_omnibus_dir/valid/embedded/bin/ruby"))
        command_instance.stub(:components).and_return({
          "failing_comp" => {
            :base_dir => "chef",
            :test_cmd => "./verify_me"
          }
        })

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
      before do
        Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH, "eg_omnibus_dir/valid/embedded/bin/ruby"))
        command_instance.stub(:components).and_return({
          "successful_comp_1" => {
            :base_dir => "berkshelf",
            :test_cmd => "./verify_me"
          },
          "successful_comp_2" => {
            :base_dir => "test-kitchen",
            :test_cmd => "./verify_me"
          }
        })

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
    end

    describe "with multiple commands with failures" do
      before do
        Gem.stub(:ruby).and_return(File.join(FIXTURES_PATH, "eg_omnibus_dir/valid/embedded/bin/ruby"))
        command_instance.stub(:components).and_return({
          "successful_comp_1" => {
            :base_dir => "berkshelf",
            :test_cmd => "./verify_me"
          },
          "successful_comp_2" => {
            :base_dir => "test-kitchen",
            :test_cmd => "./verify_me"
          },
          "failing_comp" => {
            :base_dir => "chef",
            :test_cmd => "./verify_me"
          }

        })

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
