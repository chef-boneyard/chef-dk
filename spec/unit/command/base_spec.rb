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
require 'chef-dk/command/verify'

describe ChefDK::Command::Base do
  class TestCommand < ChefDK::Command::Base
    banner "use me please"

    option :user,
      :short        => "-u",
      :long         => "--user",
      :description  => "If the user exists",
      :boolean      => true

    def run(params)
      parse_options(params)
      msg("thanks for passing me #{config[:user]}")
    end
  end

  let(:stdout_io) { StringIO.new }
  let(:command_instance) { TestCommand.new() }

  def stdout
    stdout_io.string
  end

  before do
    command_instance.stub(:stdout).and_return(stdout_io)
  end


  def run_command(options)
    command_instance.run_with_default_options(options)
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

end
