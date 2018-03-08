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
require "stringio"
require "chef-dk/chef_runner"

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
    expect(Chef::Config.solo_legacy_mode).to be true
    expect(Chef::Config.cookbook_path).to eq(default_cookbook_path)
    expect(Chef::Config.color).to be true
    expect(Chef::Config.diff_disabled).to be true
    expect(Chef::Config.file_staging_uses_destdir).to be true
  end

  it "disables atomic file updates on Windows" do
    allow(Chef::Platform).to receive(:windows?) { true }
    chef_runner.configure
    expect(Chef::Config.file_atomic_update).to be false
  end

  it "configures a formatter for the chef run" do
    expect(chef_runner.event_dispatcher).to be_a(Chef::EventDispatch::Dispatcher)

    subscribers = chef_runner.event_dispatcher.subscribers

    expect(subscribers.size).to eq(1)
    expect(subscribers.first).to be_a(ChefDK::QuieterDocFormatter)
  end

  it "extends the recipe DSL with ChefDK's extensions" do
    expect(Chef::DSL::Recipe.included_modules).to include(ChefDK::RecipeDSLExt)
  end

  it "detects the platform with ohai" do
    expect(chef_runner.ohai).to be_a(Ohai::System)
    expect(chef_runner.ohai.data["platform"]).to_not be_nil
    expect(chef_runner.ohai.data["platform_version"]).to_not be_nil
  end

  it "sets up chef policy" do
    chef_runner.configure
    expect(chef_runner.policy.node.run_list).to eq(run_list)
  end

  it "runs a chef converge" do
    chef_runner.converge
    expect(test_state[:loaded_recipes]).to eq(%w{recipe_one recipe_two})
    expect(test_state[:converged_recipes]).to eq(%w{recipe_one recipe_two})
  end

  context "when policyfile options are set in the workstation config" do

    before do
      Chef::Config.use_policyfile true
      Chef::Config.policy_name "workstation"
      Chef::Config.policy_group "test"

      # chef-client ignores `deployment_group` unless
      # `policy_document_native_api` is set to false
      Chef::Config.deployment_group "workstation-test"
      Chef::Config.policy_document_native_api false
    end

    it "unsets the options" do
      chef_runner.configure

      expect(Chef::Config.use_policyfile).to be(false)
      expect(Chef::Config.policy_name).to be_nil
      expect(Chef::Config.policy_group).to be_nil
      expect(Chef::Config.deployment_group).to be_nil
    end

    it "converges successfully" do
      expect { chef_runner.converge }.to_not raise_error
    end

  end

  context "when the embedded chef run fails" do

    let(:embedded_runner) { instance_double("Chef::Runner") }

    before do
      allow(Chef::Runner).to receive(:new).and_return(embedded_runner)
      allow(embedded_runner).to receive(:converge).and_raise("oops")
    end

    it "wraps the exception in a ChefConvergeError" do
      expect { chef_runner.converge }.to raise_error(ChefDK::ChefConvergeError)
    end

  end

  context "when cookbook_path is relative" do

    let(:default_cookbook_path) { "~/heres_some_cookbooks" }

    it "expands the path" do
      expect(chef_runner.cookbook_path).to eq(File.expand_path(default_cookbook_path))
    end

  end

end
