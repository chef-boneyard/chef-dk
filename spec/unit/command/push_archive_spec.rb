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
require "chef-dk/command/push_archive"

describe ChefDK::Command::PushArchive do

  subject(:command) { described_class.new }

  let(:policy_group) { "staging" }

  let(:archive_path) { "mypolicy-abc123.tgz" }

  it_behaves_like "a command with a UI object"

  let(:ui) { TestHelpers::TestUI.new }

  let(:chef_config_loader) { instance_double("Chef::WorkstationConfigLoader") }

  let(:config_arg) { nil }

  before do
    allow(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
  end

  describe "evaluating params" do

    before do
      command.ui = ui
    end

    context "when given no arguments" do

      it "prints the banner message and exits non-zero" do
        expect(command.run([])).to eq(1)
        expect(ui.output).to include(described_class.banner)
      end

    end

    context "when the archive path is omitted" do

      it "prints the banner message and exits non-zero" do
        expect(command.run([policy_group])).to eq(1)
        expect(ui.output).to include(described_class.banner)
      end

    end

    context "when all required arguments are given" do

      let(:params) { [ policy_group, archive_path ] }

      before do
        command.apply_params!(params)
      end

      it "disables debug by default" do
        expect(command.debug?).to be(false)
      end

      context "and debug mode is set" do

        let(:params) { [ policy_group, archive_path, "-D" ] }

        it "enables debug messages" do
          expect(command.debug?).to be(true)
        end

      end

      describe "configuring settings that depend on the chef config file" do

        before do
          expect(chef_config_loader).to receive(:load)
        end

        it "sets the policy group" do
          expect(command.policy_group).to eq(policy_group)
          expect(command.push_archive_service.policy_group).to eq(policy_group)
        end

        it "sets the path to the archive file" do
          expect(command.archive_path).to eq(archive_path)
          expect(command.push_archive_service.archive_file).to eq(File.expand_path(archive_path))
        end
      end

    end

  end

  describe "running the push operation" do

    let(:push_archive_service) { instance_double("ChefDK::PolicyfileServices::PushArchive") }

    let(:params) { [ policy_group, archive_path ] }

    before do
      allow(command).to receive(:push_archive_service).and_return(push_archive_service)
      command.ui = ui
    end

    context "when the push is successful" do

      it "exits 0" do
        expect(push_archive_service).to receive(:run)
        expect(command.run(params)).to eq(0)
      end

    end

    context "when the push in not successful" do

      let(:backtrace) { caller[0...3] }

      let(:cause) do
        e = StandardError.new("some operation failed")
        e.set_backtrace(backtrace)
        e
      end

      let(:exception) do
        ChefDK::PolicyfilePushArchiveError.new("push failed", cause)
      end

      before do
        expect(push_archive_service).to receive(:run).and_raise(exception)
      end

      it "exits non-zero" do
        expect(command.run(params)).to eq(1)
      end

    end
  end
end
