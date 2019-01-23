#
# Copyright:: Copyright (c) 2018 Chef Software Inc.
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
require "chef-dk/policyfile/git_lock_fetcher"

describe ChefDK::Policyfile::GitLockFetcher do

  let(:revision_id) { "6fe753184c8946052d3231bb4212116df28d89a3a5f7ae52832ad408419dd5eb" }
  let(:identifier) { "fab501cfaf747901bd82c1bc706beae7dc3a350c" }
  let(:git_revision) { "8404a9e0b5c27c55d529e61222e14f950b6e4171" }
  let(:rel) { "cookbooks/nested_cookbook" }
  let(:cookbook_name) { "git-cookbook" }
  let(:nested_cookbook_name) { "cookbooks/nested-cookbook" }
  let(:repo) { "https://github.com/monkeynews/bananas" }

  let(:minimal_lockfile_json) do
    <<~E
      {
        "revision_id": "#{revision_id}",
        "name": "install-example",
        "run_list": [
          "recipe[#{cookbook_name}::default]"
        ],
        "cookbook_locks": {
          "#{cookbook_name}": {
            "version": "2.3.4",
            "identifier": "#{identifier}",
            "dotted_decimal_identifier": "70567763561641081.489844270461035.258281553147148",
            "cache_key": "#{cookbook_name}-#{git_revision}",
            "source_options": {
              "git": "#{repo}",
              "revision": "#{git_revision}"
            }
          }
        },
        "default_attributes": {},
        "override_attributes": {},
        "solution_dependencies": {
          "Policyfile": [
            [
              "#{cookbook_name}",
              ">= 0.0.0"
            ]
          ],
          "dependencies": {
            "#{cookbook_name} (2.3.4)": [

            ]
          }
        }
      }
    E
  end

  def minimal_lockfile
    FFI_Yajl::Parser.parse(minimal_lockfile_json)
  end

  let(:policy_name) { "git_fetcher" }
  let(:policy_group) { "somegroup" }
  let(:storage_config) { ChefDK::Policyfile::StorageConfig.new.use_policyfile("#{tempdir}/Policyfile.rb") }

  let(:minimal_lockfile_modified) do
    minimal_lockfile.tap do |lockfile|
      lockfile["cookbook_locks"][cookbook_name]["source_options"] = {
        "git" => repo,
        "revision" => git_revision,
      }
    end
  end

  let(:minimal_lockfile_with_scm_info) do
    minimal_lockfile_modified.tap do |lockfile|
      lockfile["cookbook_locks"][cookbook_name]["scm_info"] = {
        "scm" => "git",
        "remote" => repo,
        "revision" => git_revision,
        "working_tree_clean" => true,
        "published" => true,
        "synchronized_remote_branches" => [
          "origin/master",
        ],
      }
    end
  end

  let(:source_options) do
    {
      git: repo,
      revision: git_revision,
    }
  end

  let(:shellout) { instance_double("Mixlib::ShellOut", run_command: "git") }

  describe "#lock_data" do
    subject(:lock_data) { described_class.new(policy_name, source_options, storage_config).lock_data }

    it "sets the source_options for dependencies" do
      expect(Mixlib::ShellOut).to receive(:new).and_return(shellout).at_least(:twice)
      allow(shellout).to receive(:error?).and_return(false)
      allow(shellout).to receive(:stdout).and_return(minimal_lockfile_json)
      allow(Dir).to receive(:chdir).and_return(0)

      expect(lock_data).to include(minimal_lockfile_modified)
    end

    context "when using a relative path for the policyfile" do
      let(:source_options_rel) do
        source_options.collect { |k, v| [k.to_s, v] }.to_h.merge({ "rel" => rel })
      end

      subject(:relative_path_fetcher) { described_class.new(policy_name, source_options_rel, storage_config) }

      it "omits the relative path of the policyfile from the source_options" do
        subject { described_class.new(policy_name, source_options_rel, storage_config) }

        expect(Mixlib::ShellOut).to receive(:new).and_return(shellout)
        allow(shellout).to receive(:error?).and_return(false)
        allow(shellout).to receive(:stdout).and_return(minimal_lockfile_json)
        allow(Dir).to receive(:chdir).and_return(0)
        allow_any_instance_of(described_class).to receive(:cache_path).and_return(
          Pathname.new(relative_path_fetcher.storage_config.relative_paths_root)
        )

        expect(
          relative_path_fetcher.lock_data["cookbook_locks"][cookbook_name]["source_options"]
        ).to match(
               {
                 "git" => repo,
                 "revision" => git_revision,
               }
             )
        expect(
          relative_path_fetcher.lock_data["cookbook_locks"][cookbook_name]["source_options"]
        ).not_to match(source_options_rel)
      end # it "omits the relative path of the policyfile from the source_options"
    end # context "when using a relative path for the policyfile"
  end # describe "#lock_data"
end # describe ChefDK::Policyfile::GitLockFetcher
