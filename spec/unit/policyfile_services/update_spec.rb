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

require "spec_helper"
require "chef-dk/policyfile_services/install"
require "chef-dk/policyfile/cookbook_sources"

describe ChefDK::PolicyfileServices::Install do

  include ChefDK::Helpers

  let(:working_dir) do
    path = File.join(tempdir, "policyfile_services_test_working_dir")
    Dir.mkdir(path)
    path
  end

  let(:policyfile_rb_explicit_name) { nil }

  let(:policyfile_rb_name) { policyfile_rb_explicit_name || "Policyfile.rb" }

  let(:policyfile_rb_path) { File.join(working_dir, policyfile_rb_name) }

  let(:policyfile_lock_name) { "Policyfile.lock.json" }

  let(:policyfile_lock_path) { File.join(working_dir, policyfile_lock_name) }

  let(:ui) { TestHelpers::TestUI.new }

  let(:install_service) { described_class.new(policyfile: policyfile_rb_name, ui: ui, root_dir: working_dir, overwrite: true) }

  let(:storage_config) do
    ChefDK::Policyfile::StorageConfig.new( cache_path: nil, relative_paths_root: local_cookbooks_root )
  end

  let(:policyfile_content) do
    <<-EOH
default_source :community
name 'install-example'

run_list 'top-level'

cookbook 'top-level'
cookbook 'top-level-bis'
cookbook 'b', '>= 1.2.3'
EOH
  end

  def cookbook_lock(name, version)
    {
      "version" => version,
      "identifier" => Digest::SHA256.new.hexdigest(version),
      "dotted_decimal_identifier" => "55385045718000942.66835911167097593.12604218968062",
      "cache_key" => "#{name}-#{version}-supermarket.chef.io",
      "origin" => "https://supermarket.chef.io:443/api/v1/cookbooks/#{name}/versions/#{version}/download",
      "source_options" => {
        "artifactserver" => "https://supermarket.chef.io:443/api/v1/cookbooks/#{name}/versions/#{version}/download",
        "version" => version,
      },
    }
  end

  let(:policyfile_lock_content) do
    {
      "revision_id" => "b33cb73a52bee7254eb53138ee44",
      "name" => "install-example",
      "run_list" => [ "recipe[top-level::default]" ],
      "cookbook_locks" => {
        "top-level" => cookbook_lock("top-level", "1.2.0"),
        "a" => cookbook_lock("a", "2.1.0"),
        "b" => cookbook_lock("b", "1.2.3"),
        "top-level-bis" => cookbook_lock("top-level-bis", "1.0.0"),
      },
      "default_attributes" => {},
      "override_attributes" => {},
      "solution_dependencies" => {
        "Policyfile" => [
          [ "top-level", "= 1.2.0" ],
          [ "a", "= 2.1.0" ],
          [ "b", "= 1.2.3" ],
          [ "top-level-bis", "= 1.0.0" ],
        ],
        "dependencies" => {
          "top-level (1.2.0)" => [ [ "a", "~> 2.1" ], [ "b", "~> 1.0" ] ],
          "a (2.1.0)" => [],
          "b (1.2.3)" => [],
          "top-level-bis (1.0.0)" => [],
        },
      },
    }.to_json
  end

  context "when given one cookbook to update" do
    before(:each) do
      # stub access to Policyfile.rb and Policyfile.lock.json
      expect(File).to receive(:exist?).at_least(:once).with(policyfile_rb_path).and_return(true)
      expect(File).to receive(:exist?).at_least(:once).with(policyfile_lock_path).and_return(true)

      expect(IO).to receive(:read).with(policyfile_rb_path).and_return(policyfile_content)
      expect(IO).to receive(:read).with(policyfile_lock_path).and_return(policyfile_lock_content)

      # lock generation is a no-op. Its behavior is already tested
      # elsewhere. We only check constraints changes
      expect(install_service).to receive(:generate_lock_and_install)

      expect { install_service.run(["top-level"]) }.not_to raise_error
    end
    it "allows update on cookbook to update" do
      expect(install_service.policyfile_compiler.dsl.cookbook_location_specs["top-level"].version_constraint.to_s).to eq(">= 0.0.0")
    end

    it "does not update unrelated cookbooks" do
      expect(install_service.policyfile_compiler.dsl.cookbook_location_specs["top-level-bis"].version_constraint.to_s).to eq("= 1.0.0")
    end

    it "allows update on dependencies" do
      expect(install_service.policyfile_compiler.dsl.cookbook_location_specs["a"]).to be_nil
    end

    it "preserves existing constraints from Policyfile" do
      expect(install_service.policyfile_compiler.dsl.cookbook_location_specs["b"].version_constraint.to_s).to eq(">= 1.2.3")
    end

  end

end
