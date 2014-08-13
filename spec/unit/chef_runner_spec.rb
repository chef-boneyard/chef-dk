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
require 'chef-dk/chef_runner'

describe ChefDK::ChefRunner do

  let(:stdout_io) { StringIO.new }

  let(:stderr_io) { StringIO.new }

  let(:default_cookbook_path) do
    File.expand_path("chef-runner-cookbooks", fixtures_path)
  end

  let(:run_list) { [ "recipe[test_cookbook::recipe_one]", "recipe[test_cookbook::recipe_two]" ] }

  subject(:chef_runner) do
    r = ChefDK::ChefRunner.new(default_cookbook_path, run_list)
    allow(r).to receive(:stdout).and_return(stdout_io)
    allow(r).to receive(:stderr).and_return(stderr_io)
    r
  end

  it "sets up Chef::Config" do
    chef_runner.configure
    expect(Chef::Config.solo).to be true
    expect(Chef::Config.cookbook_path).to eq(default_cookbook_path)
    expect(Chef::Config.color).to be true
    expect(Chef::Config.diff_disabled).to be true
  end

  it "disables atomic file updates on Windows" do
    allow(Chef::Platform).to receive(:windows?) { true }
    chef_runner.configure
    expect(Chef::Config.file_atomic_update).to be false
  end

  it "configures a formatter for the chef run" do
    expect(chef_runner.formatter).to be_a(Chef::Formatters::Doc)
  end

  it "detects the platform with ohai" do
    expect(chef_runner.ohai).to be_a(Ohai::System)
    expect(chef_runner.ohai.data["platform"]).to_not be_nil
    expect(chef_runner.ohai.data["platform_version"]).to_not be_nil
  end

  it "sets up chef policy" do
    expect(chef_runner.policy.node.run_list).to eq(run_list)
  end

  it "runs a chef converge" do
    chef_runner.converge
    expect(test_state[:loaded_recipes]).to eq([ "recipe_one", "recipe_two" ])
    expect(test_state[:converged_recipes]).to eq([ "recipe_one", "recipe_two" ])
  end
end


