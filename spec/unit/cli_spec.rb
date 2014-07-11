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
require 'stringio'
require 'chef-dk/cli'
require 'unit/fixtures/command/cli_test_command'

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
    <<-E
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
    cli.run
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
    let(:argv) { %w[-h] }

    it "prints the help output" do
      run_cli(0)
      expect(stdout).to eq(base_help_message)
    end
  end

  context "given -v" do
    let(:argv) { %w[-v] }

    it "prints the version" do
      run_cli(0)
      expect(stdout).to eq(version_message)
    end
  end

  context "given an invalid/unknown subcommand" do
    let(:argv) { %w[ancient-aliens] }

    it "prints an 'unknown command' message and the help output" do
      expected_err = "Unknown command `ancient-aliens'.\n"

      run_cli(1)

      expect(stderr).to eq(expected_err)
      expect(stdout).to eq(base_help_message)
    end

  end

  context "given a valid subcommand" do
    let(:argv) { %w[example with some args --and-an-option] }

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
      params = %w[with some args --and-an-option]
      run_cli(23)
      expect(test_result[:params]).to eq(params)
    end
  end

end
