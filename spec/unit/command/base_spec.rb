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
require "chef-dk/command/verify"

describe ChefDK::Command::Base do
  class TestCommand < ChefDK::Command::Base
    banner "use me please"

    option :argue,
      short:       "-a ARG",
      long:        "--arg ARG",
      description: "An option with a required argument"

    option :user,
      short: "-u",
      long: "--user",
      description: "If the user exists",
      boolean: true

    def run(params)
      parse_options(params)
      msg("thanks for passing me #{config[:user]}")
    end
  end

  let(:stderr_io) { StringIO.new }
  let(:stdout_io) { StringIO.new }
  let(:command_instance) { TestCommand.new() }
  let(:enforce_license) { false }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  before do
    allow(command_instance).to receive(:stdout).and_return(stdout_io)
    allow(command_instance).to receive(:stderr).and_return(stderr_io)
  end

  def run_command(options)
    command_instance.run_with_default_options(enforce_license, options)
  end

  it "should print the banner for -h" do
    run_command(["-h"])
    expect(stdout).to include("use me please\n")
  end

  it "should print the banner for --help" do
    run_command(["--help"])
    expect(stdout).to include("use me please\n")
  end

  it "prints the options along with the banner when displaying the help message" do
    run_command(["--help"])
    expect(stdout).to include("-u, --user                       If the user exists")
  end

  it "should print the version for -v" do
    run_command(["-v"])
    expect(stdout).to eq("Chef Development Kit Version: #{ChefDK::VERSION}\n")
  end

  it "should print the version for --version" do
    run_command(["--version"])
    expect(stdout).to eq("Chef Development Kit Version: #{ChefDK::VERSION}\n")
  end

  it "should run the command passing in the custom options for long custom options" do
    run_command(["--user"])
    expect(stdout).to eq("thanks for passing me true\n")
  end

  it "should run the command passing in the custom options for short custom options" do
    run_command(["-u"])
    expect(stdout).to eq("thanks for passing me true\n")
  end

  describe "when enforce_license is true" do
    let(:enforce_license) { true }

    it "calls the license acceptance library" do
      expect(LicenseAcceptance::Acceptor).to receive(:check_and_persist!).with("chef-dk", ChefDK::VERSION.to_s)
      run_command([])
      expect(stdout).to eq("thanks for passing me \n")
    end
  end

  describe "when given invalid options" do

    it "prints the help banner and exits gracefully" do
      expect(run_command(%w{-foo})).to eq(1)

      expect(stderr).to eq("ERROR: invalid option: -foo\n\n")

      expected = <<~E
        use me please
            -a, --arg ARG                    An option with a required argument
                --chef-license ACCEPTANCE    Accept the license for this product and any contained products ('accept', 'accept-no-persist', or 'accept-silent')
            -h, --help                       Show this message
            -u, --user                       If the user exists
            -v, --version                    Show chef version

      E
      expect(stdout).to eq(expected)
    end

  end

  describe "when given an option that requires an argument with no argument" do

    it "prints the help banner and exits gracefully" do
      expect(run_command(%w{-a})).to eq(1)

      expect(stderr).to eq("ERROR: missing argument: -a\n\n")

      expected = <<~E
        use me please
            -a, --arg ARG                    An option with a required argument
                --chef-license ACCEPTANCE    Accept the license for this product and any contained products ('accept', 'accept-no-persist', or 'accept-silent')
            -h, --help                       Show this message
            -u, --user                       If the user exists
            -v, --version                    Show chef version

      E
      expect(stdout).to eq(expected)

    end

  end

  describe "when parsing Chef's configuration fails" do

    let(:exception_message) do
      <<~MESSAGE
        You have an error in your config file /Users/ddeleo/.chef/config.rb (Chef::Exceptions::ConfigurationError)

        Mixlib::Config::UnknownConfigOptionError: Cannot set unsupported config value foo.
          /Users/person/.chef/config.rb:50:in `from_string'
        Relevant file content:
         49: chefdk.generator_cookbook "~/.chef/code_generator"
         50: chefdk.foo "bar"
         51:

      MESSAGE
    end

    let(:exception) { Chef::Exceptions::ConfigurationError.new(exception_message) }

    before do
      allow(command_instance).to receive(:run).and_raise(exception)
    end

    it "exits non-zero" do
      expect(run_command([])).to eq(1)
    end

    it "prints the exception message to stderr" do
      run_command([])
      expect(stderr).to include(exception_message)
    end

  end

end
