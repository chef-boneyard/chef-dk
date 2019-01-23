#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
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
require "chef-dk/policyfile/local_lock_fetcher"

describe ChefDK::Policyfile::LocalLockFetcher do

  let(:minimal_lockfile_json) do
    <<~E
      {
        "revision_id": "6fe753184c8946052d3231bb4212116df28d89a3a5f7ae52832ad408419dd5eb",
        "name": "install-example",
        "run_list": [
          "recipe[local-cookbook::default]"
        ],
        "cookbook_locks": {
          "local-cookbook": {
            "version": "2.3.4",
            "identifier": "fab501cfaf747901bd82c1bc706beae7dc3a350c",
            "dotted_decimal_identifier": "70567763561641081.489844270461035.258281553147148",
            "source": "cookbooks/local-cookbook",
            "cache_key": null,
            "scm_info": null,
            "source_options": {
              "path": "../cookbooks/local-cookbook"
            }
          }
        },
        "default_attributes": {},
        "override_attributes": {},
        "solution_dependencies": {
          "Policyfile": [
            [
              "local-cookbook",
              ">= 0.0.0"
            ]
          ],
          "dependencies": {
            "local-cookbook (2.3.4)": [

            ]
          }
        }
      }
    E
  end

  def minimal_lockfile
    FFI_Yajl::Parser.parse(minimal_lockfile_json)
  end

  let(:minimal_lockfile_modified) do
    minimal_lockfile.tap do |lockfile|
      lockfile["cookbook_locks"]["local-cookbook"]["source_options"] = { "path" => "foo/bar/cookbooks/local-cookbook" }
    end
  end

  [:relative, :absolute].each do |mode|
    context "When path is #{mode}" do
      let(:path) { "foo/bar/baz/foo.lock.json" }
      let(:lock_file_path_abs) { "#{tempdir}/#{path}" }
      let(:lock_file_path) do
        if mode == :relative
          path
        else
          lock_file_path_abs
        end
      end
      let(:storage_config) { ChefDK::Policyfile::StorageConfig.new.use_policyfile("#{tempdir}/Policyfile.rb") }

      before do
        reset_tempdir
        FileUtils.mkdir_p(Pathname.new(lock_file_path_abs).dirname)
        File.open(lock_file_path_abs, "w") { |file| file.write(minimal_lockfile_json) }
      end

      after do
        reset_tempdir
      end

      subject(:fetcher) { described_class.new("foo", source_options, storage_config) }

      context "when the path is a file" do
        context "and the file exists" do
          let(:source_options) do
            {
              path: lock_file_path,
            }
          end

          let(:source_options_for_lock) { source_options }

          it "loads the policy from disk" do
            expect(fetcher.lock_data).to eq(minimal_lockfile_modified)
          end

          it "returns source_options_for_lock" do
            expect(fetcher.source_options).to eq(source_options)
          end

          it "applies can apply source options from the lock" do
            fetcher.apply_locked_source_options(source_options_for_lock)
            expect(fetcher.lock_data).to eq(minimal_lockfile_modified)
          end
        end

        context "and the file does not exist" do
          let(:source_options) do
            {
              path: Pathname.new(lock_file_path).dirname.join("dne.json.lock").to_s,
            }
          end

          it "raises an error" do
            expect { fetcher.lock_data }.to raise_error(ChefDK::LocalPolicyfileLockNotFound)
          end
        end
      end

      context "when the path is a directory" do
        context "and the file exists" do
          let(:source_options) do
            {
              path: Pathname.new(lock_file_path).dirname.to_s,
            }
          end

          let(:source_options_for_lock) { source_options }

          it "loads the policy from disk" do
            expect(fetcher.lock_data).to eq(minimal_lockfile_modified)
          end

          it "returns source_options_for_lock" do
            expect(fetcher.source_options).to eq(source_options)
          end

          it "applies can apply source options from the lock" do
            fetcher.apply_locked_source_options(source_options_for_lock)
            expect(fetcher.lock_data).to eq(minimal_lockfile_modified)
          end
        end

        context "and the file does not exist" do
          let(:source_options) do
            {
              path: Pathname.new(lock_file_path).dirname.parent.to_s,
            }
          end

          it "raises an error" do
            expect { fetcher.lock_data }.to raise_error(ChefDK::LocalPolicyfileLockNotFound, /provide the file name as part of the path/)
          end
        end
      end
    end
  end
end
