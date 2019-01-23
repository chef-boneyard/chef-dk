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
require "shared/command_with_ui_object"
require "chef-dk/command/update"

describe ChefDK::Command::Update do

  it_behaves_like "a command with a UI object"

  let(:params) { [] }

  let(:command) do
    c = described_class.new
    c.apply_params!(params)
    c
  end

  let(:install_service) { instance_double(ChefDK::PolicyfileServices::Install) }

  let(:update_attrs_service) { instance_double(ChefDK::PolicyfileServices::UpdateAttributes) }

  it "disables debug by default" do
    expect(command.debug?).to be(false)
  end

  it "doesn't set a config path by default" do
    expect(command.config_path).to be_nil
  end

  context "when debug mode is set" do

    let(:params) { [ "-D" ] }

    it "enables debug" do
      expect(command.debug?).to be(true)
    end
  end

  context "when an explicit config file path is given" do

    let(:params) { %w{ -c ~/.chef/alternate_config.rb } }

    let(:chef_config_loader) { instance_double("Chef::WorkstationConfigLoader") }

    it "sets the config file path to the given value" do
      expect(command.config_path).to eq("~/.chef/alternate_config.rb")
    end

    it "loads the config from the given path" do
      expect(Chef::WorkstationConfigLoader).to receive(:new)
        .with("~/.chef/alternate_config.rb")
        .and_return(chef_config_loader)
      expect(chef_config_loader).to receive(:load)
      expect(command.chef_config).to eq(Chef::Config)
    end

  end

  context "when attributes update mode is set" do

    let(:params) { ["-a"] }

    it "enables attributes update mode" do
      expect(command.update_attributes_only?).to be(true)
    end

    it "creates an attributes update service object" do
      expect(ChefDK::PolicyfileServices::UpdateAttributes).to receive(:new)
        .with(policyfile: nil, ui: command.ui, root_dir: Dir.pwd, chef_config: anything)
        .and_return(update_attrs_service)
      expect(command.attributes_updater).to eq(update_attrs_service)
    end
  end

  context "with no arguments" do

    it "does not specify a policyfile relative path" do
      expect(command.policyfile_relative_path).to be(nil)
    end

    it "creates the installer service with a `nil` policyfile path" do
      expect(ChefDK::PolicyfileServices::Install).to receive(:new)
        .with(policyfile: nil, ui: command.ui, root_dir: Dir.pwd, config: Chef::Config, overwrite: true)
        .and_return(install_service)
      expect(command.installer).to eq(install_service)
    end

  end

  context "with an explicit policyfile relative path" do

    let(:params) { [ "MyPolicy.rb" ] }

    it "respects the user-supplied path" do
      expect(command.policyfile_relative_path).to eq("MyPolicy.rb")
    end

    it "creates the installer service with the specified policyfile path" do
      expect(ChefDK::PolicyfileServices::Install).to receive(:new)
        .with(policyfile: "MyPolicy.rb", ui: command.ui, root_dir: Dir.pwd, config: Chef::Config, overwrite: true)
        .and_return(install_service)
      expect(command.installer).to eq(install_service)
    end

  end

  describe "running the install" do

    let(:ui) { TestHelpers::TestUI.new }

    before do
      command.ui = ui
      allow(command).to receive(:installer).and_return(install_service)
    end

    context "when the command is successful" do
      before do
        expect(install_service).to receive(:run)
        expect(ChefDK::PolicyfileServices::UpdateAttributes).to receive(:new)
          .with(policyfile: nil, ui: command.ui, root_dir: Dir.pwd, chef_config: anything)
          .and_return(update_attrs_service)
        expect(update_attrs_service).to receive(:run)
      end

      it "returns 0" do
        expect(command.run).to eq(0)
      end
    end

    context "when the command is unsuccessful" do

      let(:backtrace) { caller[0...3] }

      let(:cause) do
        e = StandardError.new("some operation failed")
        e.set_backtrace(backtrace)
        e
      end

      let(:exception) do
        ChefDK::PolicyfileInstallError.new("install failed", cause)
      end

      before do
        expect(install_service).to receive(:run).and_raise(exception)
        expect(ChefDK::PolicyfileServices::UpdateAttributes).to receive(:new)
          .with(policyfile: nil, ui: command.ui, root_dir: Dir.pwd, chef_config: anything)
          .and_return(update_attrs_service)
        expect(update_attrs_service).to receive(:run)
      end

      it "returns 1" do
        expect(command.run).to eq(1)
      end

      it "displays the exception and cause" do
        expected_error_text = <<~E
          Error: install failed
          Reason: (StandardError) some operation failed

        E

        command.run
        expect(ui.output).to eq(expected_error_text)
      end

      context "and debug is enabled" do

        let(:params) { ["-D"] }

        it "displays the exception and cause with backtrace" do
          expected_error_text = <<~E
            Error: install failed
            Reason: (StandardError) some operation failed


          E

          expected_error_text << backtrace.join("\n") << "\n"

          command.run
          expect(ui.output).to eq(expected_error_text)
        end
      end

    end

  end

  describe "running attributes update" do

    let(:params) { ["-a"] }

    let(:ui) { TestHelpers::TestUI.new }

    before do
      command.ui = ui
      allow(command).to receive(:attributes_updater).and_return(update_attrs_service)
    end

    context "when the command runs successfully" do

      before do
        expect(update_attrs_service).to receive(:run)
      end

      it "exits with success" do
        expect(command.run).to eq(0)
      end
    end

    context "when the command fails" do

      let(:backtrace) { caller[0...3] }

      let(:cause) do
        e = StandardError.new("some operation failed")
        e.set_backtrace(backtrace)
        e
      end

      let(:exception) do
        ChefDK::PolicyfileUpdateError.new("Failed to update Policyfile lock", cause)
      end

      before do
        expect(update_attrs_service).to receive(:run).and_raise(exception)
      end

      it "exits 1" do
        expect(command.run).to eq(1)
      end

      it "displays the exception and cause" do
        expected_error_text = <<~E
          Error: Failed to update Policyfile lock
          Reason: (StandardError) some operation failed

        E

        command.run
        expect(ui.output).to eq(expected_error_text)
      end

      context "and debug is enabled" do

        let(:params) { ["-a", "-D"] }

        it "displays the exception and cause with backtrace" do
          expected_error_text = <<~E
            Error: Failed to update Policyfile lock
            Reason: (StandardError) some operation failed


          E

          expected_error_text << backtrace.join("\n") << "\n"

          command.run
          expect(ui.output).to eq(expected_error_text)
        end
      end

    end

  end
end
