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
require "chef-dk/command/push"

describe ChefDK::Command::Push do

  it_behaves_like "a command with a UI object"

  let(:policy_group) { "dev" }

  let(:params) { [policy_group] }

  let(:command) do
    described_class.new
  end

  let(:push_service) { instance_double(ChefDK::PolicyfileServices::Push) }

  let(:chef_config_loader) { instance_double("Chef::WorkstationConfigLoader") }

  let(:chef_config) { double("Chef::Config") }

  let(:config_arg) { nil }

  before do
    stub_const("Chef::Config", chef_config)
    allow(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
  end

  context "after evaluating params" do

    before do
      command.apply_params!(params)
    end

    it "disables debug by default" do
      expect(command.debug?).to be(false)
    end

    describe "when configuring components that depend on chef config" do

      before do
        expect(chef_config_loader).to receive(:load)
      end

      it "reads the chef/knife config" do
        expect(command.chef_config).to eq(chef_config)
      end

      it "configures the Push service" do
        expect(ChefDK::PolicyfileServices::Push).to receive(:new)
          .with(policyfile: nil, ui: command.ui, policy_group: policy_group, config: chef_config, root_dir: Dir.pwd)
          .and_return(push_service)
        expect(command.push).to eq(push_service)
      end

      context "and an explicit Policyfile is given" do

        let(:params) { [policy_group, "MyPolicy.rb"] }

        it "configures the Push service with the given Policyfile" do
          expect(ChefDK::PolicyfileServices::Push).to receive(:new)
            .with(policyfile: "MyPolicy.rb", ui: command.ui, policy_group: policy_group, config: chef_config, root_dir: Dir.pwd)
            .and_return(push_service)
          expect(command.push).to eq(push_service)
        end

      end
    end

    context "when debug mode is set" do

      let(:params) { [ policy_group, "-D" ] }

      it "enables debug" do
        expect(command.debug?).to be(true)
      end

    end

  end

  describe "running the push operation" do

    let(:ui) { TestHelpers::TestUI.new }

    before do
      command.ui = ui
    end

    context "when invoked without arguments" do

      let(:params) { [] }

      it "prints the banner and returns 1" do
        expect(command.run).to eq(1)
      end

    end

    context "with valid arguments" do

      before do
        expect(command).to receive(:push).and_return(push_service)
      end

      context "when the push is successful" do

        before do
          expect(push_service).to receive(:run)
        end

        it "returns 0" do
          expect(command.run(params)).to eq(0)
        end

      end

      context "when the push operation raises an exception" do

        let(:backtrace) { caller[0...3] }

        let(:cause) do
          e = StandardError.new("some operation failed")
          e.set_backtrace(backtrace)
          e
        end

        let(:exception) do
          ChefDK::PolicyfilePushError.new("push failed", cause)
        end

        before do
          expect(push_service).to receive(:run).and_raise(exception)
        end

        it "exits 1" do
          expect(command.run(params)).to eq(1)
        end

        it "describes the error" do
          command.run(params)

          expected_output = <<~E
            Error: push failed
            Reason: (StandardError) some operation failed

          E

          expect(ui.output).to eq(expected_output)
        end

        context "when debug is enabled" do

          before do
            params << "-D"
          end

          it "includes the backtrace in the error" do

            command.run(params)

            expected_output = <<~E
              Error: push failed
              Reason: (StandardError) some operation failed


            E
            expected_output << backtrace.join("\n") << "\n"

            expect(ui.output).to eq(expected_output)
          end

        end

      end
    end

  end

end
