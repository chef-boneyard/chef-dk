#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "chef-dk/command/show_policy"

describe ChefDK::Command::ShowPolicy do

  it_behaves_like "a command with a UI object"

  subject(:command) do
    described_class.new
  end

  let(:show_policy_service) { command.show_policy_service }

  let(:chef_config_loader) { instance_double("Chef::WorkstationConfigLoader") }

  let(:chef_config) { double("Chef::Config") }

  # nil means the config loader will do the default path lookup
  let(:config_arg) { nil }

  before do
    stub_const("Chef::Config", chef_config)
    allow(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
  end

  describe "parsing args and options" do
    let(:params) { [] }

    before do
      command.apply_params!(params)
    end

    context "when given a path to the config" do

      let(:params) { %w{ -c ~/otherstuff/config.rb } }

      let(:config_arg) { "~/otherstuff/config.rb" }

      before do
        expect(chef_config_loader).to receive(:load)
      end

      it "reads the chef/knife config" do
        expect(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
        expect(command.chef_config).to eq(chef_config)
        expect(show_policy_service.chef_config).to eq(chef_config)
      end

    end

    describe "settings that require loading chef config" do

      before do
        allow(chef_config_loader).to receive(:load)
      end

      context "with no params" do

        it "disables debug by default" do
          expect(command.debug?).to be(false)
        end

        it "is configured to show all policies across all groups" do
          expect(show_policy_service.show_all_policies?).to be(true)
        end

        it "disables displaying orphans" do
          expect(command.show_orphans?).to be(false)
          expect(show_policy_service.show_orphans?).to be(false)
        end

      end

      context "when debug mode is set" do

        let(:params) { [ "-D" ] }

        it "enables debug" do
          expect(command.debug?).to be(true)
        end

      end

      context "when --show-orphans is given" do

        let(:params) { %w{ -o } }

        it "enables displaying orphans" do
          expect(command.show_orphans?).to be(true)
          expect(show_policy_service.show_orphans?).to be(true)
        end

      end

      context "when given a policy name" do

        let(:params) { %w{ appserver } }

        it "is not configured to show all policies" do
          expect(show_policy_service.show_all_policies?).to be(false)
        end

        it "is configured to show the given policy" do
          expect(command.policy_name).to eq("appserver")
          expect(show_policy_service.policy_name).to eq("appserver")
        end

      end

      context "when given a policy name and a policy group name" do

        let(:params) { %w{ appserver production } }

        it "is not configured to show all policies" do
          expect(show_policy_service.show_all_policies?).to be(false)
        end

        it "is configured to show the given policy" do
          expect(command.policy_name).to eq("appserver")
          expect(show_policy_service.policy_name).to eq("appserver")
        end

        it "is configured to display the exact revision for the given policy+group" do
          expect(command.policy_group).to eq("production")
          expect(show_policy_service.policy_group).to eq("production")
        end

      end

    end
  end

  describe "running the command" do

    let(:ui) { TestHelpers::TestUI.new }

    before do
      allow(chef_config_loader).to receive(:load)
      command.ui = ui
    end

    context "when given too many arguments" do

      let(:params) { %w{ appserver policygroup wut-is-this } }

      it "shows usage and exits" do
        expect(command.run(params)).to eq(1)
      end

    end

    context "when the list service raises an exception" do

      let(:backtrace) { caller[0...3] }

      let(:cause) do
        e = StandardError.new("some operation failed")
        e.set_backtrace(backtrace)
        e
      end

      let(:exception) do
        ChefDK::PolicyfileListError.new("Failed to list policies", cause)
      end

      before do
        allow(command.show_policy_service).to receive(:run).and_raise(exception)
      end

      it "prints a debugging message and exits non-zero" do
        expect(command.run([])).to eq(1)

        expected_output = <<~E
          Error: Failed to list policies
          Reason: (StandardError) some operation failed

        E

        expect(ui.output).to eq(expected_output)
      end

      context "when debug is enabled" do

        it "includes the backtrace in the error" do

          command.run(%w{ -D })

          expected_output = <<~E
            Error: Failed to list policies
            Reason: (StandardError) some operation failed


          E
          expected_output << backtrace.join("\n") << "\n"

          expect(ui.output).to eq(expected_output)
        end

      end

    end

    context "when the list service executes successfully" do

      before do
        expect(command.show_policy_service).to receive(:run)
      end

      it "exits 0" do
        expect(command.run([])).to eq(0)
      end

    end

  end
end
