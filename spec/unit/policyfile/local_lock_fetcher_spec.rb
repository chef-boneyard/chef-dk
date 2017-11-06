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
    <<-E
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
        "path": "cookbooks/local-cookbook"
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

  let(:lock_file_path) { "#{tempdir}/foo.lock.json" }

  before do
    reset_tempdir
    File.open(lock_file_path, "w") { |file| file.write(minimal_lockfile_json) }
  end

  after do
    reset_tempdir
  end

  let(:minimal_lockfile) { FFI_Yajl::Parser.parse(minimal_lockfile_json) }

  let(:source_options) do
    {
      local: lock_file_path,
    }
  end

  subject(:fetcher) { described_class.new("foo", source_options) }

  it "loads the policy from disk" do
    expect(fetcher.lock_data).to eq(minimal_lockfile)
  end
end
