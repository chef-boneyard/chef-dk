#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "chef-dk/policyfile/comparison_base"

describe "Policyfile Comparison Bases" do

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

  let(:minimal_lockfile) { FFI_Yajl::Parser.parse(minimal_lockfile_json) }

  describe ChefDK::Policyfile::ComparisonBase::Local do

    let(:policyfile_lock_relpath) { "Policyfile.lock.json" }

    subject(:comparison_base) { described_class.new(policyfile_lock_relpath) }

    before do
      reset_tempdir
    end

    after do
      reset_tempdir
    end

    it "has the lockfile relative path" do
      expect(comparison_base.policyfile_lock_relpath).to eq(policyfile_lock_relpath)
    end

    it "is named local:RELATIVE_PATH" do
      expect(comparison_base.name).to eq("local:#{policyfile_lock_relpath}")
    end

    context "when the local lock doesn't exist" do

      it "raises an exception when reading the lockfile" do
        Dir.chdir(tempdir) do
          expect { comparison_base.lock }.to raise_error(ChefDK::LockfileNotFound)
        end
      end

    end

    context "when the local policyfile lock is not readable", :skip_on_windows do

      before do
        Dir.chdir(tempdir) do
          FileUtils.touch(policyfile_lock_relpath)
          allow(File).to receive(:readable?).with(policyfile_lock_relpath).and_return(false)
        end
      end

      it "raises an exception" do
        Dir.chdir(tempdir) do
          expect { comparison_base.lock }.to raise_error(ChefDK::LockfileNotFound)
        end
      end

    end

    context "when the local policyfile lock is malformed" do

      before do
        Dir.chdir(tempdir) do
          File.open(policyfile_lock_relpath, "w+") { |f| f.print("}}}}}}") }
        end
      end

      it "raises an exception" do
        Dir.chdir(tempdir) do
          expect { comparison_base.lock }.to raise_error(ChefDK::MalformedLockfile)
        end
      end

    end

    context "when the local lock exists and is valid JSON" do

      before do
        Dir.chdir(tempdir) do
          File.open(policyfile_lock_relpath, "w+") { |f| f.print(minimal_lockfile_json) }
        end
      end

      it "reads the local lock and parses the JSON" do
        Dir.chdir(tempdir) do
          expect(comparison_base.lock).to eq(minimal_lockfile)
        end
      end

    end

  end

  describe ChefDK::Policyfile::ComparisonBase::Git do

    let(:ref) { "master" }

    let(:policyfile_lock_relpath) { "policies/MyPolicy.lock.json" }

    subject(:comparison_base) { described_class.new(ref, policyfile_lock_relpath) }

    it "has the policyfile lock relative path it was created with" do
      expect(comparison_base.policyfile_lock_relpath).to eq(policyfile_lock_relpath)
    end

    it "has the ref it was created with" do
      expect(comparison_base.ref).to eq(ref)
    end

    it "is named git:REF" do
      expect(comparison_base.name).to eq("git:master")
    end

    it "creates a `git show` command for the policyfile lock and ref" do
      expect(comparison_base.git_cmd_string).to eq("git show master:./policies/MyPolicy.lock.json")
      expect(comparison_base.git_cmd.command).to eq("git show master:./policies/MyPolicy.lock.json")
    end

    context "when the git command fails" do

      before do
        allow(comparison_base.git_cmd).to receive(:run_command)
        allow(comparison_base.git_cmd).to receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        allow(comparison_base.git_cmd).to receive(:stderr).and_return("fatal: Not a git repository (or any of the parent directories): .git\n")
      end

      it "raises an exception when reading the lockfile" do
        expect { comparison_base.lock }.to raise_error(ChefDK::GitError)
      end

    end

    context "when the git command succeeds" do

      before do
        allow(comparison_base.git_cmd).to receive(:run_command)
        allow(comparison_base.git_cmd).to receive(:error!).and_return(nil)
      end

      context "and the JSON is malformed" do

        before do
          allow(comparison_base.git_cmd).to receive(:stdout).and_return("}}}}}")
        end

        it "raises an exception" do
          expect { comparison_base.lock }.to raise_error(ChefDK::MalformedLockfile)
        end

      end

      context "and the JSON is well-formed" do

        before do
          allow(comparison_base.git_cmd).to receive(:stdout).and_return(minimal_lockfile_json)
        end

        it "reads the lockfile and parses the JSON" do
          expect(comparison_base.lock).to eq(minimal_lockfile)
        end
      end

    end

  end

  describe ChefDK::Policyfile::ComparisonBase::PolicyGroup do

    let(:group) { "acceptance" }
    let(:policy_name) { "chatserver" }
    let(:http_client) { instance_double("Chef::ServerAPI", url: "https://chef.example/organizations/monkeynews") }

    subject(:comparison_base) { described_class.new(group, policy_name, http_client) }

    it "has the group it was created with" do
      expect(comparison_base.group).to eq(group)
    end

    it "has the policy_name it was created with" do
      expect(comparison_base.policy_name).to eq(policy_name)
    end

    it "has the HTTP client it was created with" do
      expect(comparison_base.http_client).to eq(http_client)
    end

    it "is named policy_group:GROUP" do
      expect(comparison_base.name).to eq("policy_group:#{group}")
    end

    context "when there is a non-404 HTTP error fetching the policyfile lock" do

      let(:response) do
        Net::HTTPResponse.send(:response_class, "500").new("1.0", "500", "Internal Server Error").tap do |r|
          r.instance_variable_set(:@body, "oops")
        end
      end

      let(:http_exception) do
        begin
          response.error!
        rescue => e
          e
        end
      end

      before do
        allow(http_client).to receive(:get).and_raise(http_exception)
      end

      it "raises an exception" do
        exception = nil
        begin
          comparison_base.lock
        rescue => exception
          expect(exception).to be_a_kind_of(ChefDK::PolicyfileDownloadError)
          expect(exception.message).to eq("HTTP error attempting to fetch policyfile lock from https://chef.example/organizations/monkeynews")
          expect(exception.cause).to eq(http_exception)
        end
        expect(exception).to_not be_nil
      end

    end

    context "when the server returns 404 fetching the policyfile lock" do

      let(:response) do
        Net::HTTPResponse.send(:response_class, "404").new("1.0", "404", "Not Found").tap do |r|
          r.instance_variable_set(:@body, "nothin' here, chief")
        end
      end

      let(:http_exception) do
        begin
          response.error!
        rescue => e
          e
        end
      end

      before do
        allow(http_client).to receive(:get).and_raise(http_exception)
      end

      it "raises an exception" do
        exception = nil
        begin
          comparison_base.lock
        rescue => exception
          expect(exception).to be_a_kind_of(ChefDK::PolicyfileDownloadError)
          expect(exception.message).to eq("No policyfile lock named 'chatserver' found in policy_group 'acceptance' at https://chef.example/organizations/monkeynews")
          expect(exception.cause).to eq(http_exception)
        end
        expect(exception).to_not be_nil
      end

    end

    context "when a non-HTTP error occurs fetching the policyfile lock" do

      before do
        allow(http_client).to receive(:get).and_raise(Errno::ECONNREFUSED)
      end

      it "raises an exception" do
        expect { comparison_base.lock }.to raise_error(ChefDK::PolicyfileDownloadError)
      end

    end

    context "when the policyfile lock is fetched from the server" do

      before do
        expect(http_client).to receive(:get)
          .with("policy_groups/acceptance/policies/chatserver")
          .and_return(minimal_lockfile)
      end

      it "returns the policyfile lock data" do
        expect(comparison_base.lock).to eq(minimal_lockfile)
      end

    end

  end
end
