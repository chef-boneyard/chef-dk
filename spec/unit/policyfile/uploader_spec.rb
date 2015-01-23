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
require 'chef-dk/policyfile/uploader'

# We load this here to ensure we get the "verifying doubles" behavior from
# RSpec. It's not used by Policyfile::Uploader, but it's a collaborator.
require 'chef-dk/authenticated_http'

describe ChefDK::Policyfile::Uploader do

  let(:policyfile_lock_data) do
    {
      "name"=> "example",
      "run_list"=> [ "recipe[omnibus::default]" ],
      "cookbook_locks"=> {
        "omnibus"=> {
          "version"=> "2.2.0",
          "identifier"=> "64b3e64306cff223206348e46af545b19032b170",
          "dotted_decimal_identifier"=> "28345299219435506.9887234981653237.76628930769264",
          "cache_key"=> "omnibus-2cf98f9797cacce9c8688fc4e74858b858e2bc14",
          "origin"=> "git@github.com:opscode-cookbooks/omnibus.git",
          "source_options"=> {
            "git"=> "git@github.com:opscode-cookbooks/omnibus.git",
            "revision"=> "2cf98f9797cacce9c8688fc4e74858b858e2bc14",
            "branch"=> "master"
          }
        }
      }
    }
  end

  let(:policyfile_lock) { instance_double("ChefDK::PolicyfileLock", name: "example",
                                                                    to_lock: policyfile_lock_data) }

  let(:policy_group) { "unit-test" }

  let(:http_client) { instance_double("ChefDK::AuthenticatedHTTP") }

  let(:policy_document_native_api) { false }

  let(:uploader) do
    described_class.new(policyfile_lock,
                        policy_group,
                        http_client: http_client,
                        policy_document_native_api: policy_document_native_api)
  end

  let(:policyfile_as_data_bag_item) do

    policyfile_as_data_bag_item = {
      "id" => "example-unit-test",
      "name" => "data_bag_item_policyfiles_example-unit-test",
      "data_bag" => "policyfiles"
    }
    policyfile_as_data_bag_item["raw_data"] = policyfile_lock_data.dup
    policyfile_as_data_bag_item["raw_data"]["id"] = "example-unit-test"
    policyfile_as_data_bag_item["json_class"] = "Chef::DataBagItem"
    policyfile_as_data_bag_item
  end

  it "has a lockfile" do
    expect(uploader.policyfile_lock).to eq(policyfile_lock)
  end

  it "has a policy group" do
    expect(uploader.policy_group).to eq(policy_group)
  end

  it "has an HTTP client" do
    expect(uploader.http_client).to eq(http_client)
  end

  describe "uploading documents in compat mode" do

    let(:cookbook_locks) { {} }
    let(:cookbook_versions) { {} }

    let(:existing_cookbook_on_remote) do
      {"apt"=>
        {"url"=>"http://localhost:8889/cookbooks/apt",
         "versions"=>
          [{"url"=>
             "http://localhost:8889/cookbooks/apt/46097674477573307.43471642740453733.243606720748315",
            "version"=>"46097674477573307.43471642740453733.243606720748315"}]},
       "build-essential"=>
        {"url"=>"http://localhost:8889/cookbooks/build-essential",
         "versions"=>
          [{"url"=>
             "http://localhost:8889/cookbooks/build-essential/67369247788170534.26353953100055918.55660493423796",
            "version"=>"67369247788170534.26353953100055918.55660493423796"}]},
       "java"=>
        {"url"=>"http://localhost:8889/cookbooks/java",
         "versions"=>
          [{"url"=>
             "http://localhost:8889/cookbooks/java/5664982062912610.52588194571203830.6215746262253",
            "version"=>"5664982062912610.52588194571203830.6215746262253"}]},
       "jenkins"=>
        {"url"=>"http://localhost:8889/cookbooks/jenkins",
         "versions"=>
          [{"url"=>
             "http://localhost:8889/cookbooks/jenkins/69194928762630300.30177357398946006.269829039948647",
            "version"=>"69194928762630300.30177357398946006.269829039948647"}]}
      }
    end

    before do
      allow(policyfile_lock).to receive(:cookbook_locks).and_return(cookbook_locks)
    end

    def lock_double(name, dotted_decimal_id)
      cache_path = "/home/user/cache_path/#{name}"

      lock = instance_double("ChefDK::Policyfile::CookbookLock",
                             name: name,
                             version: "1.0.0",
                             identifier: "64b3e64306cff223206348e46af545b19032b170",
                             dotted_decimal_identifier: dotted_decimal_id,
                             cookbook_path: cache_path)

      cookbook_version = instance_double("Chef::CookbookVersion",
                                         name: name,
                                         version: dotted_decimal_id)

      allow(ChefDK::Policyfile::ReadCookbookForCompatModeUpload).
        to receive(:load).
        with(name, dotted_decimal_id, cache_path).
        and_return(cookbook_version)

      cookbook_versions[name] = cookbook_version
      cookbook_locks[name] = lock

      lock
    end

    context "when configured for policy document compat mode" do

      let(:policyfiles_data_bag) { {"name" => "policyfiles" } }

      it "ensures a data bag named 'policyfiles' exists" do
        expect(http_client).to receive(:post).with('data', policyfiles_data_bag)
        uploader.data_bag_create
      end

      it "does not error when the 'policyfiles' data bag exists" do
        response = double("Net::HTTP response", code: "409")
        error = Net::HTTPServerException.new("conflict", response)
        expect(http_client).to receive(:post).with('data', {"name" => "policyfiles"}).and_raise(error)
        expect { uploader.data_bag_create }.to_not raise_error
      end

      it "uploads the policyfile as a data bag item" do
        response = double("Net::HTTP response", code: "404")
        error = Net::HTTPServerException.new("Not Found", response)
        expect(http_client).to receive(:put).
          with('data/policyfiles/example-unit-test', policyfile_as_data_bag_item).
          and_raise(error)
        expect(http_client).to receive(:post).
          with('data/policyfiles', policyfile_as_data_bag_item)

        uploader.data_bag_item_create
      end

      it "replaces an existing policyfile on the server if it exists" do
        expect(http_client).to receive(:put).
          with('data/policyfiles/example-unit-test', policyfile_as_data_bag_item)
        uploader.data_bag_item_create
      end

      it "creates the data bag and item to upload the policy" do
        expect(http_client).to receive(:post).with('data', policyfiles_data_bag)
        expect(http_client).to receive(:put).
          with('data/policyfiles/example-unit-test', policyfile_as_data_bag_item)
        uploader.upload_policy
      end

    end

    context "when configured for policy document native mode" do

      let(:policy_document_native_api) { true }

      it "enables native document mode for policyfiles" do
        expect(uploader.using_policy_document_native_api?).to be(true)
      end

      it "uploads the policyfile to the native API" do
        expect(http_client).to receive(:put).
          with('/policies/unit-test/example', policyfile_lock_data)

        uploader.upload_policy
      end

    end

    it "enumerates the cookbooks already on the server" do
      expect(http_client).to receive(:get).with('cookbooks?num_versions=all').and_return(existing_cookbook_on_remote)
      expect(uploader.existing_cookbook_on_remote).to eq(existing_cookbook_on_remote)
    end

    context "with an empty policyfile lock" do

      it "has an empty list of cookbooks for possible upload" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)

        expect(uploader.cookbook_versions_for_policy).to eq([])
      end

      it "has an empty list of cookbooks that need to be uploaded" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)

        expect(uploader.cookbook_versions_to_upload).to eq([])
      end

    end

    context "with a set of cookbooks that don't exist on the server" do

      before do
        lock_double("my_apache2", "123.456.789")
        lock_double("my_jenkins", "321.654.987")
      end

      it "lists the cookbooks in the lock as possibly needing to be uploaded" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)

        expected_versions_for_policy = cookbook_versions.keys.map do |cb_name|
          cb = cookbook_versions[cb_name]
          lock = cookbook_locks[cb_name]
          ChefDK::Policyfile::Uploader::LockedCookbookForUpload.new(cb, lock)
        end

        expect(uploader.cookbook_versions_for_policy).to eq(expected_versions_for_policy)
      end

      it "lists all cookbooks in the lock as needing to be uploaded" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)
        expect(http_client).to receive(:get).with('cookbooks?num_versions=all').and_return(existing_cookbook_on_remote)

        expect(uploader.cookbook_versions_to_upload).to eq(cookbook_versions.values)
      end

      it "uploads the cookbooks and then the policy" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)
        expect(http_client).to receive(:get).with('cookbooks?num_versions=all').and_return(existing_cookbook_on_remote)

        cookbook_uploader = instance_double("Chef::CookbookUploader")
        expect(Chef::CookbookUploader).to receive(:new).
          with(cookbook_versions.values, :rest => http_client).
          and_return(cookbook_uploader)
        expect(cookbook_uploader).to receive(:upload_cookbooks)

        # behavior for these tested above
        expect(uploader).to receive(:data_bag_create)
        expect(uploader).to receive(:data_bag_item_create)

        uploader.upload
      end

    end

    context "with a set of cookbooks where some already exist on the server" do

      before do
        # These are new:
        lock_double("my_apache2", "123.456.789")
        lock_double("my_jenkins", "321.654.987")

        # Have this one:
        lock_double("build-essential", "67369247788170534.26353953100055918.55660493423796")
      end

      let(:expected_cookbooks_for_upload) do
        [
          cookbook_versions["my_apache2"],
          cookbook_versions["my_jenkins"]
        ]
      end

      it "lists only cookbooks not on the server as needing to be uploaded" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)
        expect(http_client).to receive(:get).with('cookbooks?num_versions=all').and_return(existing_cookbook_on_remote)


        expect(uploader.cookbook_versions_to_upload).to eq(expected_cookbooks_for_upload)
      end

      it "uploads the cookbooks and then the policy" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)
        expect(http_client).to receive(:get).with('cookbooks?num_versions=all').and_return(existing_cookbook_on_remote)

        cookbook_uploader = instance_double("Chef::CookbookUploader")
        expect(Chef::CookbookUploader).to receive(:new).
          with(expected_cookbooks_for_upload, :rest => http_client).
          and_return(cookbook_uploader)
        expect(cookbook_uploader).to receive(:upload_cookbooks)

        # behavior for these tested above
        expect(uploader).to receive(:data_bag_create)
        expect(uploader).to receive(:data_bag_item_create)

        uploader.upload
      end

    end

    context "with a set of cookbooks that all exist on the server" do

      before do
        # Have this one:
        lock_double("build-essential", "67369247788170534.26353953100055918.55660493423796")
      end

      let(:expected_cookbooks_for_upload) do
        []
      end

      it "lists no cookbooks as needing to be uploaded" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)
        expect(http_client).to receive(:get).with('cookbooks?num_versions=all').and_return(existing_cookbook_on_remote)

        expect(uploader.cookbook_versions_to_upload).to eq(expected_cookbooks_for_upload)
      end

      it "skips cookbooks uploads, then uploads the policy" do
        expect(policyfile_lock).to receive(:validate_cookbooks!)
        expect(http_client).to receive(:get).with('cookbooks?num_versions=all').and_return(existing_cookbook_on_remote)

        expect(uploader.uploader).to_not receive(:upload_cookbooks)

        # behavior for these tested above
        expect(uploader).to receive(:data_bag_create)
        expect(uploader).to receive(:data_bag_item_create)

        uploader.upload
      end
    end
  end

end

