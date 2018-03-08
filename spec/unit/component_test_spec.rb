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
require "chef-dk/component_test"
require "pathname"

describe ChefDK::ComponentTest do

  let(:component) do
    ChefDK::ComponentTest.new("berkshelf").tap do |c|
      c.base_dir = "berkshelf"
    end
  end

  it "defines the component" do
    expect(component.name).to eq("berkshelf")
  end

  it "sets the component base directory" do
    expect(component.base_dir).to eq("berkshelf")
  end

  it "defines a default unit test" do
    expect(component.run_unit_test.exitstatus).to eq(0)
    expect(component.run_unit_test.stdout).to eq("")
    expect(component.run_unit_test.stderr).to eq("")
  end

  it "defines a default integration test" do
    expect(component.run_integration_test.exitstatus).to eq(0)
    expect(component.run_integration_test.stdout).to eq("")
    expect(component.run_integration_test.stderr).to eq("")
  end

  it "defines a default smoke test" do
    expect(component.run_smoke_test.exitstatus).to eq(0)
    expect(component.run_smoke_test.stdout).to eq("")
    expect(component.run_smoke_test.stderr).to eq("")
  end

  context "with basic tests defined" do

    let(:result) { {} }

    before do
      # capture a reference to results hash so we can use it in tests.
      result_hash = result
      component.tap do |c|
        c.unit_test { result_hash[:unit_test] = true }
        c.integration_test { result_hash[:integration_test] = true }
        c.smoke_test { result_hash[:smoke_test] = true }
      end
    end

    it "defines a unit test block" do
      component.run_unit_test
      expect(result[:unit_test]).to be true
    end

    it "defines an integration test block" do
      component.run_integration_test
      expect(result[:integration_test]).to be true
    end

    it "defines a smoke test block" do
      component.run_smoke_test
      expect(result[:smoke_test]).to be true
    end

  end

  context "with tests that shell out to commands" do

    let(:omnibus_root) { File.join(fixtures_path, "eg_omnibus_dir/valid/") }

    before do
      component.tap do |c|
        # Have to set omnibus dir so command can run with correct cwd
        c.omnibus_root = omnibus_root

        c.base_dir = "embedded/apps/berkshelf"

        c.unit_test { sh("true") }

        c.integration_test { sh("ruby -e 'puts Dir.pwd'", env: { "RUBYOPT" => "" }) }

        c.smoke_test { run_in_tmpdir("ruby -e 'puts Dir.pwd'", env: { "RUBYOPT" => "" }) }
      end
    end

    it "shells out and returns the shell out object" do
      expect(component.run_unit_test.exitstatus).to eq(0)
      expect(component.run_unit_test.stdout).to eq("")
      expect(component.run_unit_test.stderr).to eq("")
    end

    it "runs the command in the app's root" do
      result = component.run_integration_test
      expected_path = Pathname.new(File.join(omnibus_root, "embedded/apps/berkshelf")).realpath
      expect(Pathname.new(result.stdout.strip).realpath).to eq(expected_path)
    end

    it "runs commands in a temporary directory when specified" do
      result = component.run_smoke_test

      parent_of_cwd = Pathname.new(result.stdout.strip).parent.realpath
      tempdir = Pathname.new(Dir.tmpdir).realpath
      expect(parent_of_cwd).to eq(tempdir)
    end

  end

end
