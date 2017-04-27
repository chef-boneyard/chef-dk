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
require "chef-dk/command/provision"

describe ChefDK::Command::Provision do

  it_behaves_like "a command with a UI object"

  let(:command) do
    described_class.new
  end

  let(:push_service) { instance_double(ChefDK::PolicyfileServices::Push) }

  let(:chef_config_loader) { instance_double("Chef::WorkstationConfigLoader") }

  let(:chef_config) { double("Chef::Config") }

  let(:config_arg) { nil }

  before do
    ChefDK::ProvisioningData.reset

    stub_const("Chef::Config", chef_config)
    allow(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
  end

  describe "evaluating CLI options and arguments" do

    let(:ui) { TestHelpers::TestUI.new }

    before do
      command.ui = ui
    end

    describe "when input is invalid" do

      context "when not enough arguments are given" do

        let(:params) { [] }

        it "prints usage and exits non-zero" do
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("You must specify a POLICY_GROUP or disable policyfiles with --no-policy")
        end

      end

      context "when --no-policy is combined with policy arguments" do

        let(:params) { %w{ --no-policy some-policy-group } }

        it "prints usage and exits non-zero" do
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("The --no-policy flag cannot be combined with policyfile arguments")
        end

      end

      context "when a POLICY_GROUP is given but neither of --sync or --policy-name are given" do

        let(:params) { %w{ some-policy-group } }

        it "prints usage and exits non-zero" do
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("You must pass either --sync or --policy-name to provision machines in policyfile mode")
        end

      end

      context "when both --sync and --policy-name are given" do

        let(:params) { %w{ some-policy-group --policy-name foo --sync} }

        it "prints usage and exits non-zero" do
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("The --policy-name and --sync arguments cannot be combined")
        end

      end

      context "when too many arguments are given" do

        let(:params) { %w{ policygroup extraneous-argument --sync } }

        it "prints usage and exits non-zero" do
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("Too many arguments")
        end

      end
    end

    describe "when input is valid" do

      let(:context) { ChefDK::ProvisioningData.context }

      shared_examples "common_optional_options" do

        context "with default option values" do

          it "node name is not specified" do
            expect(command.node_name).to eq(nil)
            expect(context.node_name).to eq(nil)
          end

          it "sets the cookbook path to CWD" do
            # this is cookbook_path in the chef sense, a directory with cookbooks in it.
            expect(command.provisioning_cookbook_path).to eq(Dir.pwd)
          end

          it "sets the cookbook name to 'provision'" do
            expect(command.provisioning_cookbook_name).to eq("provision")
          end

          it "sets the recipe to 'default'" do
            expect(command.recipe).to eq("default")
            expect(command.chef_runner.run_list).to eq(["recipe[provision::default]"])
          end

          it "sets the default action to converge" do
            expect(command.default_action).to eq(:converge)
            expect(context.action).to eq(:converge)
          end

        end

        context "with -n NODE_NAME" do

          let(:extra_params) { %w{ -n example-node } }

          it "sets the default requested node name" do
            expect(command.node_name).to eq("example-node")
            expect(context.node_name).to eq("example-node")
          end

        end

        context "with --cookbook COOKBOOK_PATH" do

          let(:extra_params) { %w{ --cookbook ~/mystuff/my-provision-cookbook } }

          let(:expected_cookbook_path) { File.expand_path("~/mystuff") }
          let(:expected_cookbook_name) { "my-provision-cookbook" }

          it "sets the cookbook path" do
            # this is cookbook_path in the chef sense, a directory with cookbooks in it.
            expect(command.provisioning_cookbook_path).to eq(expected_cookbook_path)
          end

          it "sets the cookbook name" do
            expect(command.provisioning_cookbook_name).to eq(expected_cookbook_name)
          end

        end

        context "with -c CONFIG_FILE" do

          let(:config_arg) { "~/somewhere_else/knife.rb" }

          let(:extra_params) { [ "-c", config_arg ] }

          it "loads config from the specified location" do
            # The configurable module uses config[:config_file]
            expect(command.config[:config_file]).to eq("~/somewhere_else/knife.rb")
          end

        end

        context "with -r MACHINE_RECIPE" do

          let(:extra_params) { %w{ -r ec2cluster } }

          it "sets the recipe to run as specified" do
            expect(command.recipe).to eq("ec2cluster")
            expect(command.chef_runner.run_list).to eq(["recipe[provision::ec2cluster]"])
          end

        end

        context "with --target" do

          let(:extra_params) { %w{ -t 192.168.255.123 } }

          it "sets the target host to the given value" do
            expect(context.target).to eq("192.168.255.123")
          end

        end

        context "with --opt" do
          context "with one user-specified option" do
            let(:extra_params) { %w{ --opt color=ebfg } }

            it "sets the given option name to the given value" do
              expect(context.opts.color).to eq("ebfg")
            end
          end

          context "with an option given as a quoted arg with spaces" do

            let(:extra_params) { [ "--opt", "color = ebfg" ] }

            it "sets the given option name to the given value" do
              expect(context.opts.color).to eq("ebfg")
            end
          end

          context "with an option with an '=' in it" do

            let(:extra_params) { [ "--opt", "api_key=abcdef==" ] }

            it "sets the given option name to the given value" do
              expect(context.opts.api_key).to eq("abcdef==")
            end
          end

          context "with an option with a space in it" do

            let(:extra_params) { [ "--opt", "full_name=Bobo T. Clown" ] }

            it "sets the given option name to the given value" do
              expect(context.opts.full_name).to eq("Bobo T. Clown")
            end
          end

          context "with multiple options given" do
            let(:extra_params) { %w{ --opt color=ebfg --opt nope=seppb } }

            it "sets the given option name to the given value" do
              expect(context.opts.color).to eq("ebfg")
              expect(context.opts.nope).to eq("seppb")
            end
          end
        end

        context "with -d" do

          let(:extra_params) { %w{ -d } }

          it "sets the default action to destroy" do
            expect(command.default_action).to eq(:destroy)
            expect(context.action).to eq(:destroy)
          end

        end

      end # shared examples

      context "when --no-policy is given" do

        before do
          allow(chef_config_loader).to receive(:load)
          allow(command).to receive(:push).and_return(push_service)

          allow(chef_config).to receive(:ssl_verify_mode).and_return(:verify_peer)

          command.apply_params!(params)
          command.setup_context
        end

        let(:extra_params) { [] }
        let(:params) { %w{ --no-policy } + extra_params }

        it "disables policyfile integration" do
          expect(command.enable_policyfile?).to be(false)
        end

        it "generates chef config with no policyfile options" do
          expected_config = <<-CONFIG
# SSL Settings:
ssl_verify_mode :verify_peer

CONFIG
          expect(context.chef_config).to eq(expected_config)
        end

        include_examples "common_optional_options"

      end # when --no-policy is given

      context "when --sync POLICYFILE argument is given" do

        let(:policy_data) { { "name" => "myapp" } }

        before do
          allow(chef_config_loader).to receive(:load)

          allow(ChefDK::PolicyfileServices::Push).to receive(:new).
            with(policyfile: given_policyfile_path, ui: ui, policy_group: given_policy_group, config: chef_config, root_dir: Dir.pwd).
            and_return(push_service)

          allow(push_service).to receive(:policy_data).and_return(policy_data)

          command.apply_params!(params)
          command.setup_context
        end

        context "with explicit policyfile relative path" do

          let(:given_policyfile_path) { "policies/OtherPolicy.rb" }

          let(:given_policy_group) { "some-policy-group" }

          let(:params) { [ given_policy_group, "--sync", given_policyfile_path ] }

          it "sets policy group" do
            expect(command.policy_group).to eq(given_policy_group)
            expect(context.policy_group).to eq(given_policy_group)
          end

          it "sets policy name" do
            expect(command.policy_name).to eq("myapp")
            expect(context.policy_name).to eq("myapp")
          end

        end

        context "with implicit policyfile relative path" do

          let(:given_policyfile_path) { nil }

          let(:given_policy_group) { "some-policy-group" }

          let(:extra_params) { [] }

          let(:params) { [ given_policy_group, "--sync" ] + extra_params }

          before do
            allow(chef_config).to receive(:ssl_verify_mode).and_return(:verify_peer)
          end

          it "sets policy group" do
            expect(command.policy_group).to eq(given_policy_group)
            expect(context.policy_group).to eq(given_policy_group)
          end

          it "sets policy name" do
            expect(command.policy_name).to eq("myapp")
            expect(context.policy_name).to eq("myapp")
          end

          it "generates chef config with policyfile options" do
            expected_config = <<-CONFIG
# SSL Settings:
ssl_verify_mode :verify_peer

# Policyfile Settings:
use_policyfile true
policy_document_native_api true

policy_group "some-policy-group"
policy_name "myapp"

CONFIG
            expect(context.chef_config).to eq(expected_config)
          end

          include_examples "common_optional_options"

        end

      end # when --sync POLICYFILE argument is given

      context "when a --policy-name is given" do

        let(:given_policy_group) { "some-policy-group" }

        let(:extra_params) { [] }

        let(:params) { [ given_policy_group, "--policy-name", "myapp" ] + extra_params }

        before do
          command.apply_params!(params)
          command.setup_context

          allow(chef_config).to receive(:ssl_verify_mode).and_return(:verify_peer)
        end

        it "sets policy group" do
          expect(command.policy_group).to eq(given_policy_group)
          expect(context.policy_group).to eq(given_policy_group)
        end

        it "sets policy name" do
          expect(command.policy_name).to eq("myapp")
          expect(context.policy_name).to eq("myapp")
        end

        it "generates chef config with policyfile options" do
          expected_config = <<-CONFIG
# SSL Settings:
ssl_verify_mode :verify_peer

# Policyfile Settings:
use_policyfile true
policy_document_native_api true

policy_group "some-policy-group"
policy_name "myapp"

CONFIG
          expect(context.chef_config).to eq(expected_config)
        end

        include_examples "common_optional_options"

      end
    end

  end

  describe "running the provision cookbook" do

    let(:ui) { TestHelpers::TestUI.new }

    before do
      allow(chef_config_loader).to receive(:load)
      allow(command).to receive(:push).and_return(push_service)
      command.ui = ui
    end

    let(:provision_cookbook_path) { File.expand_path("provision", Dir.pwd) }
    let(:provision_recipe_path) { File.join(provision_cookbook_path, "recipes", "default.rb") }

    let(:chef_runner) { instance_double("ChefDK::ChefRunner") }

    let(:params) { %w{ policygroup --sync } }

    context "when the provision cookbook doesn't exist" do

      before do
        allow(File).to receive(:exist?).with(provision_cookbook_path).and_return(false)
      end

      it "prints an error and exits non-zero" do
        expect(command.run(params)).to eq(1)
        expect(ui.output).to include("Provisioning cookbook not found at path #{provision_cookbook_path}")
      end

    end

    context "when the provision cookbook doesn't have the requested recipe" do

      before do
        allow(File).to receive(:exist?).with(provision_cookbook_path).and_return(true)
        allow(File).to receive(:exist?).with(provision_recipe_path).and_return(false)
      end

      it "prints an error and exits non-zero" do
        expect(command.run(params)).to eq(1)
        expect(ui.output).to include("Provisioning recipe not found at path #{provision_recipe_path}")
      end

    end

    context "when the policyfile upload fails" do

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
        allow(File).to receive(:exist?).with(provision_cookbook_path).and_return(true)
        allow(File).to receive(:exist?).with(provision_recipe_path).and_return(true)

        expect(push_service).to receive(:run).and_raise(exception)
      end

      it "prints an error and exits non-zero" do
        expected_output = <<-E
Error: push failed
Reason: (StandardError) some operation failed

E
        expect(command.run(params)).to eq(1)
        expect(ui.output).to include(expected_output)
      end

    end

    context "when the chef run fails" do

      let(:base_exception) { StandardError.new("Something went wrong") }
      let(:exception) { ChefDK::ChefConvergeError.new("Chef failed to converge: #{base_exception}", base_exception) }

      let(:policy_data) { { "name" => "myapp" } }

      before do
        allow(File).to receive(:exist?).with(provision_cookbook_path).and_return(true)
        allow(File).to receive(:exist?).with(provision_recipe_path).and_return(true)

        allow(push_service).to receive(:policy_data).and_return(policy_data)

        expect(push_service).to receive(:run)

        allow(command).to receive(:chef_runner).and_return(chef_runner)
        allow(chef_runner).to receive(:cookbook_path).and_return(Dir.pwd)
        expect(chef_runner).to receive(:converge).and_raise(exception)
      end

      it "prints an error and exits non-zero" do
        expect(command.run(params)).to eq(1)
        expect(ui.output).to include("Error: Chef failed to converge")
        expect(ui.output).to include("Reason: (StandardError) Something went wrong")
      end

    end

    context "when the chef run is successful" do

      before do
        allow(File).to receive(:exist?).with(provision_cookbook_path).and_return(true)
        allow(File).to receive(:exist?).with(provision_recipe_path).and_return(true)
        allow(command).to receive(:chef_runner).and_return(chef_runner)
        allow(chef_runner).to receive(:cookbook_path).and_return(Dir.pwd)

        expect(chef_runner).to receive(:converge)
      end

      context "when using --no-policy" do

        let(:params) { %w{ --no-policy } }

        it "exits 0" do
          return_value = command.run(params)
          expect(ui.output).to eq("")
          expect(return_value).to eq(0)
        end

      end

      context "with --policy-name" do

        let(:params) { %w{ policygroup --policy-name otherapp } }

        it "exits 0" do
          return_value = command.run(params)
          expect(ui.output).to eq("")
          expect(return_value).to eq(0)
        end
      end

      context "with --sync" do

        let(:policy_data) { { "name" => "myapp" } }

        before do
          allow(push_service).to receive(:policy_data).and_return(policy_data)
          expect(push_service).to receive(:run)
        end

        it "exits 0" do
          return_value = command.run(params)
          expect(ui.output).to eq("")
          expect(return_value).to eq(0)
        end

      end

    end

  end
end
