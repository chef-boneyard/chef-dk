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
require "chef-dk/policyfile/remote_lock_fetcher"

describe ChefDK::Policyfile::RemoteLockFetcher do

  let(:minimal_lockfile_json) do
    <<~E
      {
        "revision_id": "6fe753184c8946052d3231bb4212116df28d89a3a5f7ae52832ad408419dd5eb",
        "name": "install-example",
        "run_list": [
          "recipe[remote-cookbook::default]"
        ],
        "cookbook_locks": {
          "remote-cookbook": {
            "version": "2.3.4",
            "identifier": "fab501cfaf747901bd82c1bc706beae7dc3a350c",
            "dotted_decimal_identifier": "70567763561641081.489844270461035.258281553147148",
            "cache_key": null,
            "origin": "http://my.chef.server/remote-cookbook/download",
            "source_options": {
              "artifactserver": "http://my.chef.server/remote-cookbook/download",
              "version": "2.3.4"
            }
          }
        },
        "default_attributes": {},
        "override_attributes": {},
        "solution_dependencies": {
          "Policyfile": [
            [
              "remote-cookbook",
              ">= 0.0.0"
            ]
          ],
          "dependencies": {
            "remote-cookbook (2.3.4)": [

            ]
          }
        }
      }
    E
  end

  let(:minimal_lockfile) do
    FFI_Yajl::Parser.parse(minimal_lockfile_json)
  end

  describe "#lock_data" do
    let(:http) { instance_double(Chef::HTTP, url: "http://my.chef.server/policy.lock.json") }
    let(:storage_config) { ChefDK::Policyfile::StorageConfig.new.use_policyfile("#{tempdir}/Policyfile.rb") }
    let(:source_options) { { remote: "http://my.chef.server/policy.lock.json" } }

    before do
      expect(Chef::HTTP).to receive(:new).with(source_options[:remote]).and_return(http)
    end

    subject(:fetcher) { described_class.new("foo", source_options) }

    context "when the http.get returns valid json" do
      context "source_options does not include 'path'" do
        it "returns the parsed json" do
          expect(http).to receive(:get).with("").and_return(minimal_lockfile_json)
          expect(fetcher.lock_data).to eq(minimal_lockfile)
        end
      end

      context "source_options includes 'path'" do
        let(:minimal_lockfile_json_w_path) do
          FFI_Yajl::Encoder.encode(
            minimal_lockfile.tap do |lockfile|
              lockfile["cookbook_locks"]["remote-cookbook"]["source_options"] = {
                "path" => "../remote-cookbook",
              }
            end
          )
        end

        it "raises ChefDK::InvalidLockfile" do
          expect(http).to receive(:get).with("").and_return(minimal_lockfile_json_w_path)
          expect { fetcher.lock_data } .to raise_error(ChefDK::InvalidLockfile, /Invalid cookbook path/)
        end
      end
    end

    context "when the http.get returns a 404" do
      let(:err) { Net::HTTPNotFound.new(1, 404, "msg") }
      let(:err_re) { /No remote policyfile lock/ }
      it "raises a PolicyfileLockDownloadError" do
        expect(http).to receive(:get).with("").and_raise(Net::HTTPError.new("msg", err))
        expect { fetcher.lock_data }.to raise_error(ChefDK::PolicyfileLockDownloadError, err_re)
      end
    end

    context "when the http.get returns a non-404" do
      let(:err) { Net::HTTPServerError.new(1, 500, "msg") }
      let(:err_re) { /HTTP error attempting to fetch policyfile lock/ }
      it "raises a PolicyfileLockDownloadError" do
        expect(http).to receive(:get).with("").and_raise(Net::HTTPError.new("msg", err))
        expect { fetcher.lock_data }.to raise_error(ChefDK::PolicyfileLockDownloadError, err_re)
      end
    end

    context "when the http.get returns a RuntimeError" do
      it "reraises" do
        expect(http).to receive(:get).with("").and_raise("foo")
        expect { fetcher.lock_data }.to raise_error("foo")
      end
    end
  end
end
