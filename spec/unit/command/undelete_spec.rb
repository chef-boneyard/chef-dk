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
require "chef-dk/command/undelete"

describe ChefDK::Command::Undelete do

  it_behaves_like "a command with a UI object"

  subject(:command) do
    described_class.new
  end

  let(:undelete_service) { command.undelete_service }

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

    let(:ui) { TestHelpers::TestUI.new }

    before do
      command.ui = ui
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
        expect(undelete_service.chef_config).to eq(chef_config)
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

        it "enables listing undo records" do
          expect(command.list_undo_records?).to be(true)
        end

      end

      context "when debug mode is set" do

        let(:params) { [ "-D" ] }

        it "enables debug" do
          expect(command.debug?).to be(true)
        end

      end

      context "when --last is given" do

        let(:params) { %w{ -l } }

        it "disables list mode" do
          expect(command.list_undo_records?).to be(false)
        end

        it "has no undo id" do
          expect(command.undo_record_id).to be_nil
          expect(command.undelete_service.undo_record_id).to be_nil
        end

      end

      context "when given a undo record id via --id" do

        let(:undo_id) { "20150827180422" }

        let(:params) { [ "-i", undo_id ] }

        it "disables list mode" do
          expect(command.list_undo_records?).to be(false)
        end

        it "is configured to perform undo for the given undo id" do
          expect(command.undo_record_id).to eq(undo_id)
          expect(command.undelete_service.undo_record_id).to eq(undo_id)
        end

      end

      context "when exclusive options --last and --id are given" do

        let(:params) { %w{ --last --id foo } }

        it "emits an error message saying they are exclusive and exits" do
          expect(ui.output).to include("Error: options --last and --id cannot both be given.")
          expect(ui.output).to include(command.opt_parser.to_s)
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

      let(:params) { %w{ extra-thing } }

      it "shows usage and exits" do
        expect(command.run(params)).to eq(1)
      end

    end

    describe "running the command in list mode" do

      let(:params) { [] }

      it "lists the undo operations" do
        expect(command.undelete_service).to receive(:list)
        expect(command.run(params)).to eq(0)
      end

    end

    context "when the undelete service raises an exception" do

      let(:params) { %w{ --last } }

      let(:backtrace) { caller[0...3] }

      let(:cause) do
        e = StandardError.new("some operation failed")
        e.set_backtrace(backtrace)
        e
      end

      let(:exception) do
        ChefDK::UndeleteError.new("Failed to undelete.", cause)
      end

      before do
        allow(command.undelete_service).to receive(:run).and_raise(exception)
      end

      it "prints a debugging message and exits non-zero" do
        expect(command.run(params)).to eq(1)

        expected_output = <<~E
          Error: Failed to undelete.
          Reason: (StandardError) some operation failed

        E

        expect(ui.output).to eq(expected_output)
      end

      context "when debug is enabled" do

        it "includes the backtrace in the error" do

          command.run(params + %w{ -D })

          expected_output = <<~E
            Error: Failed to undelete.
            Reason: (StandardError) some operation failed


          E
          expected_output << backtrace.join("\n") << "\n"

          expect(ui.output).to eq(expected_output)
        end

      end

    end

    context "when the undelete service executes successfully" do

      let(:params) { %w{ --last } }

      before do
        expect(command.undelete_service).to receive(:run)
      end

      it "exits 0" do
        expect(command.run(params)).to eq(0)
      end

    end

  end
end
