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
require "chef-dk/command/diff"
require "chef-dk/service_exceptions"

describe ChefDK::Command::Diff do

  it_behaves_like "a command with a UI object"

  let(:params) { [] }

  let(:command) do
    described_class.new
  end

  let(:chef_config_loader) { instance_double("Chef::WorkstationConfigLoader") }

  let(:chef_config) { double("Chef::Config") }

  let(:config_arg) { nil }

  before do
    stub_const("Chef::Config", chef_config)
    allow(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
  end

  describe "selecting comparison bases" do

    let(:ui) { TestHelpers::TestUI.new }

    let(:http_client) { instance_double("Chef::ServerAPI") }

    let(:differ) { instance_double("ChefDK::Policyfile::Differ", run_report: nil) }

    let(:pager) { instance_double("ChefDK::Pager", ui: ui) }

    before do
      allow(ChefDK::Pager).to receive(:new).and_return(pager)
      allow(pager).to receive(:with_pager).and_yield(pager)
      allow(command).to receive(:materialize_locks).and_return(nil)
      allow(command).to receive(:differ).and_return(differ)
      allow(command).to receive(:http_client).and_return(http_client)
      command.ui = ui
    end

    context "when no base is given" do

      it "prints an error message and exits" do
        expect(command.run(params)).to eq(1)
        expect(ui.output).to include("No comparison specified")
      end

    end

    context "when an PolicyfileServiceError is encountered" do

      let(:params) { %w{ --head } }

      context "without a reason" do

        it "prints the exception successfully" do
          expect(command).to receive(:print_diff).and_raise(ChefDK::PolicyfileServiceError)
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("Error: ChefDK::PolicyfileServiceError")
        end

      end

      context "with a reason" do

        let(:err) { ChefDK::PolicyfileNestedException.new("msg", RuntimeError.new) }

        it "prints the exception and reason successfully" do
          expect(command).to receive(:print_diff).and_raise(err)
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("Error: msg\nReason: (RuntimeError) RuntimeError")
        end

      end

    end

    context "when server and git comparison bases are mixed" do

      let(:params) { %w{ --git gitref policygroup } }

      it "prints an error message and exits" do
        expect(command.run(params)).to eq(1)
        expect(ui.output).to include("Conflicting arguments and options: git and Policy Group comparisons cannot be mixed")
      end

    end

    context "when specific git comparison bases are mixed with --head" do

      let(:params) { %w{ --head --git gitref } }

      it "prints an error message and exits" do
        expect(command.run(params)).to eq(1)
        expect(ui.output).to include("Conflicting git options: --head and --git are exclusive")
      end

    end

    describe "selecting git comparison bases" do

      context "when the Policyfile isn't named" do

        let(:params) { %w{ --head } }

        it "uses Policyfile.lock.json as the local lock" do
          expect(command.run(params)).to eq(0)
          expect(command.policyfile_lock_relpath).to eq("Policyfile.lock.json")
        end

      end

      context "when the Policyfile is named" do

        context "using the --head option" do

          let(:params) { %w{ policies/OtherPolicy.rb --head } }

          it "uses the corresponding lock as the local lock" do
            expect(command.run(params)).to eq(0)
            expect(command.policyfile_lock_relpath).to eq("policies/OtherPolicy.lock.json")
          end

        end

        context "using the --git option" do

          let(:params) { %w{ policies/OtherPolicy.rb --git master } }

          it "uses the corresponding lock as the local lock" do
            expect(command.run(params)).to eq(0)
            expect(command.policyfile_lock_relpath).to eq("policies/OtherPolicy.lock.json")
          end

        end

      end

      context "when given a single commit-ish" do

        let(:params) { %w{ --git master } }

        it "compares the local lock to the commit" do
          expect(command.run(params)).to eq(0)
          expect(command.old_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::Git)
          expect(command.old_base.ref).to eq("master")
          expect(command.new_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::Local)
          expect(command.new_base.policyfile_lock_relpath).to eq("Policyfile.lock.json")
        end

      end

      context "when given two commit-ish names" do

        let(:params) { %w{ --git master...dev-branch } }

        it "compares the two commits" do
          expect(command.run(params)).to eq(0)
          expect(command.old_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::Git)
          expect(command.old_base.ref).to eq("master")
          expect(command.new_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::Git)
          expect(command.new_base.ref).to eq("dev-branch")
        end

      end

      context "when given too many commit-ish names" do

        let(:params) { %w{ --git too...many...things } }

        it "prints an error and exits" do
          expect(command.run(params)).to eq(1)
          expect(ui.output).to include("Unable to parse git comparison `too...many...things`. Only 2 references can be specified.")
        end

      end

      context "when --head is used" do

        let(:params) { %w{ --head } }

        it "compares the local lock to git HEAD" do
          expect(command.run(params)).to eq(0)
          expect(command.old_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::Git)
          expect(command.old_base.ref).to eq("HEAD")
          expect(command.new_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::Local)
          expect(command.new_base.policyfile_lock_relpath).to eq("Policyfile.lock.json")
        end

      end

    end

    describe "selecting policy group comparison bases" do

      let(:local_lock_comparison_base) do
        instance_double("ChefDK::Policyfile::ComparisonBase::Local")
      end

      before do
        allow(command).to receive(:local_lock_comparison_base).and_return(local_lock_comparison_base)
      end

      context "when the local lockfile cannot be read and parsed" do

        let(:params) { %w{ dev-group } }

        before do
          allow(local_lock_comparison_base).to receive(:lock).and_raise(ChefDK::LockfileNotFound)
        end

        it "prints an error and exits" do
          expect(command.run(params)).to eq(1)
        end

      end

      context "when the local lockfile can be read and parsed" do
        before do
          allow(local_lock_comparison_base).to receive(:lock).and_return({ "name" => "example-policy" })
          allow(command).to receive(:differ).and_return(differ)
          command.ui = ui
        end

        context "when the Policyfile isn't named" do

          let(:params) { %w{ dev-group } }

          it "uses Policyfile.lock.json as the local lock" do
            expect(command.run(params)).to eq(0)
            expect(command.policyfile_lock_relpath).to eq("Policyfile.lock.json")
          end

        end

        context "when the Policyfile is named" do

          let(:params) { %w{ policies/SomePolicy.rb dev-group } }

          it "uses the corresponding lock as the local lock" do
            expect(command.run(params)).to eq(0)
            expect(command.policyfile_lock_relpath).to eq("policies/SomePolicy.lock.json")
          end

        end

        context "when given a single policy group name" do

          let(:params) { %w{ dev-group } }

          it "compares the policy group's lock to the local lock" do
            expect(command.run(params)).to eq(0)
            expect(command.old_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::PolicyGroup)
            expect(command.old_base.group).to eq("dev-group")
            expect(command.new_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::Local)
            expect(command.new_base.policyfile_lock_relpath).to eq("Policyfile.lock.json")
          end

        end

        context "when given two policy group names" do

          let(:params) { %w{ prod-group...stage-group } }

          it "compares the two locks" do
            expect(command.run(params)).to eq(0)
            expect(command.old_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::PolicyGroup)
            expect(command.old_base.group).to eq("prod-group")
            expect(command.new_base).to be_a_kind_of(ChefDK::Policyfile::ComparisonBase::PolicyGroup)
            expect(command.new_base.group).to eq("stage-group")
          end

        end

        context "when given too many policy group names" do

          let(:params) { %w{ prod...stage...dev } }

          it "prints an error and exits" do
            expect(command.run(params)).to eq(1)
            expect(ui.output).to include("Unable to parse policy group comparison `prod...stage...dev`. Only 2 references can be specified.")
          end

        end

      end
    end
  end
end
