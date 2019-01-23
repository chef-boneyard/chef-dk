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
require "stringio"
require "chef-dk/cli"
require "unit/fixtures/command/cli_test_command"

describe ChefDK::CLI do

  let(:argv) { [] }

  # Setup a new commands map so we control what subcommands exist. Otherwise
  # we'd have to update this test for every new subcommand we add or code the
  # tests defensively.
  let(:commands_map) { ChefDK::CommandsMap.new }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  let(:base_help_message) do
    <<~E
      Usage:
          chef -h/--help
          chef -v/--version
          chef command [arguments...] [options...]


      Available Commands:
          verify   Test the embedded ChefDK applications
          gem      Runs the `gem` command in context of the embedded ruby
          example  Example subcommand for testing
    E
  end

  let(:version_message) { "Chef Development Kit Version: #{ChefDK::VERSION}\n" }

  def run_cli(expected_exit_code)
    expect(cli).to receive(:exit).with(expected_exit_code)
    expect(cli).to receive(:sanity_check!)
    cli.run
  end

  def run_cli_with_sanity_check(expected_exit_code)
    expect(cli).to receive(:exit).with(expected_exit_code)
    cli.run
  end

  def run_cli_and_validate_tool_versions
    full_version_message = version_message
    tools.each do |name, version|
      expect(cli).to receive(:shell_out).with("#{name} --version").and_return(mock_shell_out(0, "#{version["version_output"]}", ""))
      full_version_message += "#{name} version: #{version["expected_version"]}\n"
    end
    run_cli(0)
    expect(stdout).to eq(full_version_message)
  end

  def mock_shell_out(exitstatus, stdout, stderr)
    shell_out = double("mixlib_shell_out")
    allow(shell_out).to receive(:exitstatus).and_return(exitstatus)
    allow(shell_out).to receive(:stdout).and_return(stdout)
    allow(shell_out).to receive(:stderr).and_return(stderr)
    shell_out
  end

  subject(:cli) do
    ChefDK::CLI.new(argv).tap do |c|
      allow(c).to receive(:commands_map).and_return(commands_map)
      allow(c).to receive(:stdout).and_return(stdout_io)
      allow(c).to receive(:stderr).and_return(stderr_io)
    end
  end

  before do
    commands_map.builtin "verify", :Verify, desc: "Test the embedded ChefDK applications"

    commands_map.builtin "gem", :GemForwarder, require_path: "chef-dk/command/gem",
                                               desc: "Runs the `gem` command in context of the embedded ruby"

    commands_map.builtin "example", :TestCommand, require_path: "unit/fixtures/command/cli_test_command",
                                                  desc: "Example subcommand for testing"
  end

  context "given no arguments or options" do

    it "prints the help output" do
      run_cli(0)
      expect(stdout).to eq(base_help_message)
    end

  end

  context "given -h" do
    let(:argv) { %w{-h} }

    it "prints the help output" do
      run_cli(0)
      expect(stdout).to eq(base_help_message)
    end
  end

  context "given -v" do
    let(:argv) { %w{-v} }
    let(:delivery_version) { "master (454c3f37819ed508a49c971f38e42267ce8a47de)" }

    let(:tools) do
      {
        "chef-client" => {
          "version_output" => "Chef: 12.0.3",
          "expected_version" => "12.0.3",
        },
        "delivery" => {
          "version_output" => "delivery #{delivery_version}",
          "expected_version" => delivery_version,
        },
        "berks" => {
          "version_output" => "3.2.3",
          "expected_version" => "3.2.3",
        },
        "kitchen" => {
          "version_output" => "Test Kitchen version 1.3.1",
          "expected_version" => "1.3.1",
        },
        "inspec" => {
          "version_output" => "1.19.1\n\nYour version of InSpec is out of date! The latest version is 1.21.0.",
          "expected_version" => "1.19.1",
        },
      }
    end

    it "does not print versions of tools with missing or errored tools" do
      full_version_message = version_message
      tools.each do |name, version|
        if name == "berks"
          expect(cli).to receive(:shell_out).with("#{name} --version").and_return(mock_shell_out(1, "#{version["version_output"]}", ""))
          full_version_message += "#{name} version: ERROR\n"
        else
          expect(cli).to receive(:shell_out).with("#{name} --version").and_return(mock_shell_out(0, "#{version["version_output"]}", ""))
          full_version_message += "#{name} version: #{version["expected_version"]}\n"
        end
      end
      run_cli(0)
      expect(stdout).to eq(full_version_message)
    end

    it "prints the version and versions of chef-dk tools" do
      run_cli_and_validate_tool_versions
    end

    context "alternate Delivery CLI version format" do
      let(:delivery_version) { "0.0.15 (454c3f37819ed508a49c971f38e42267ce8a47de)" }

      it "prints the expected version of Delivery CLI" do
        run_cli_and_validate_tool_versions
      end
    end
  end

  context "given an invalid option" do

    let(:argv) { %w{-nope} }

    it "prints an 'invalid option message and the help output, then exits non-zero" do
      run_cli(1)
      expect(stdout).to eq(base_help_message)
      expect(stderr).to eq("invalid option: -nope\n")
    end

  end

  context "given an invalid/unknown subcommand" do
    let(:argv) { %w{ancient-aliens} }

    it "prints an 'unknown command' message and the help output" do
      expected_err = "Unknown command `ancient-aliens'.\n"

      run_cli(1)

      expect(stderr).to eq(expected_err)
      expect(stdout).to eq(base_help_message)
    end

  end

  context "given a valid subcommand" do
    let(:argv) { %w{example with some args --and-an-option} }

    def test_result
      ChefDK::Command::TestCommand.test_result
    end

    before do
      ChefDK::Command::TestCommand.reset!
    end

    it "runs the subcommand" do
      run_cli(23)
      expect(test_result[:status]).to eq(:success)
    end

    it "exits with the return code given by the subcommand" do
      run_cli(23)
    end

    it "passes arguments and options to the subcommand" do
      params = %w{with some args --and-an-option}
      run_cli(23)
      expect(test_result[:params]).to eq(params)
    end
  end

  context "sanity_check!" do

    before do
      allow(Gem).to receive(:ruby).and_return(ruby_path)
      allow(File).to receive(:exist?).with(chefdk_embedded_path).and_return(true)
      allow(cli).to receive(:omnibus_chefdk_location).and_return(chefdk_embedded_path)
    end

    context "when installed via omnibus" do

      context "on unix" do

        let(:ruby_path) { "/opt/chefdk/embedded/bin/ruby" }
        let(:chefdk_embedded_path) { "/opt/chefdk/embedded/apps/chef-dk" }

        before do
          stub_const("File::PATH_SEPARATOR", ":")
          allow(Chef::Util::PathHelper).to receive(:cleanpath) do |path|
            path
          end
        end

        it "complains if embedded is first" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chefdk/embedded/bin:/opt/chefdk/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("please reverse that order")
          expect(stderr).to include("chef shell-init")
        end

        it "complains if only embedded is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chefdk/embedded/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("you must add")
          expect(stderr).to include("chef shell-init")
        end

        it "passes when both are present in the correct order" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chefdk/bin:/opt/chefdk/embedded/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end

        it "passes when only the omnibus bin dir is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chefdk/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end
      end

      context "on windows" do

        let(:ruby_path) { "c:/opscode/chefdk/embedded/bin/ruby.exe" }
        let(:chefdk_embedded_path) { "c:/opscode/chefdk/embedded/apps/chef-dk" }

        before do
          # Would be preferable not to stub this, but `File.expand_path` does
          # weird things with windows paths on unix machines.
          #
          # I manually verified the behavior:
          #
          #   $ /c/opscode/chefdk/embedded/bin/ruby -e 'p File.expand_path(File.join(Gem.ruby, "..", "..", ".."))'
          #   "c:/opscode/chefdk"
          allow(cli).to receive(:omnibus_chefdk_location).and_return(chefdk_embedded_path)

          allow(Chef::Platform).to receive(:windows?).and_return(true)
          stub_const("File::PATH_SEPARATOR", ";")
          allow(Chef::Util::PathHelper).to receive(:cleanpath) do |path|
            path.tr "/", "\\"
          end
        end

        it "complains if embedded is first" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chefdk\embedded\bin;C:\opscode\chefdk\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("please reverse that order")
          expect(stderr).to include("chef shell-init")
        end

        it "complains if only embedded is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chefdk\embedded\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("you must add")
          expect(stderr).to include("chef shell-init")
        end

        it "passes when both are present in the correct order" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chefdk\bin;C:\opscode\chefdk\embedded\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end

        it "passes when only the omnibus bin dir is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chefdk\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chefdk/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chefdk/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end
      end
    end

    context "when not installed via omnibus" do

      let(:ruby_path) { "/Users/bog/.lots_o_rubies/2.1.2/bin/ruby" }
      let(:chefdk_embedded_path) { "/Users/bog/.lots_o_rubies/embedded/apps/chef-dk" }

      before do
        allow(File).to receive(:exist?).with(chefdk_embedded_path).and_return(false)

        [
          :omnibus_root,
          :omnibus_apps_dir,
          :omnibus_bin_dir,
          :omnibus_embedded_bin_dir,
        ].each do |method_name|
          allow(cli).to receive(method_name).and_raise(ChefDK::OmnibusInstallNotFound.new)
        end
      end

      it "skips the sanity check without error" do
        run_cli_with_sanity_check(0)
      end

    end
  end
end
