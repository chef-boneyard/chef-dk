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
require "chef-dk/chef_server_api_multi"

describe ChefDK::ChefServerAPIMulti do

  let(:url) { "https://chef.example/organizations/myorg" }

  let(:opts) do
    {
      signing_key_filename: "/path/to/key.pem",
      client_name: "example-user",
    }
  end

  let(:expected_server_api_opts) do
    {
      signing_key_filename: "/path/to/key.pem",
      client_name: "example-user",
      keepalives: true,
    }
  end

  let(:chef_server_api) { instance_double("Chef::ServerAPI") }

  subject(:server_api_multi) { described_class.new(url, opts) }

  before do
    # clean out thread local storage or else `chef_server_api` instance double
    # will get re-used across test examples and rspec will complain:
    Thread.current[:chef_server_api_multi] = nil
    allow(Chef::ServerAPI).to receive(:new).with(url, expected_server_api_opts).and_return(chef_server_api)
  end

  it "has a url" do
    expect(server_api_multi.url).to eq(url)
  end

  it "has an options hash for Chef::ServerAPI, with `keepalives: true` added" do
    expect(server_api_multi.opts).to eq(expected_server_api_opts)
  end

  it "creates a thread-local Chef::ServerAPI object for requests" do
    server_api_multi.client_for_thread # force `||=` to run
    expect(server_api_multi.client_for_thread).to eq(Thread.current[:chef_server_api_multi])
  end

  describe "when keepalives are disabled" do

    let(:opts) do
      {
        signing_key_filename: "/path/to/key.pem",
        client_name: "example-user",
        keepalives: false,
      }
    end

    it "does not override disabling them" do
      expect(server_api_multi.opts[:keepalives]).to be(false)
    end

  end

  describe "delegating request methods to thread-local ServerAPI object" do

    it "delegates #head" do
      expect(chef_server_api).to receive(:head).with("/foo")
      server_api_multi.head("/foo")
    end

    it "delegates #get" do
      expect(chef_server_api).to receive(:get).with("/foo")
      server_api_multi.get("/foo")
    end

    it "delegates #put" do
      expect(chef_server_api).to receive(:put).with("/foo", "data")
      server_api_multi.put("/foo", "data")
    end

    it "delegates #post" do
      expect(chef_server_api).to receive(:post).with("/foo", "data")
      server_api_multi.post("/foo", "data")
    end

    it "delegates #delete" do
      expect(chef_server_api).to receive(:delete).with("/foo")
      server_api_multi.delete("/foo")
    end

    it "delegates #streaming_request" do
      expect(chef_server_api).to receive(:streaming_request).with("/foo")
      server_api_multi.streaming_request("/foo")
    end

    it "passes a block argument to #streaming_request" do
      expect(chef_server_api).to receive(:streaming_request).with("/foo").and_yield
      x = 0
      server_api_multi.streaming_request("/foo") { x = 5 }
      expect(x).to eq(5)
    end

  end
end
