#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

require "chef/run_context"
require "chef/cookbook/cookbook_collection"
require "chef/node"
require "chef/event_dispatch/dispatcher"
require "chef/formatters/base"

require "ohai/system"

require "chef-dk/command/generator_commands/chef_exts/generator_desc_resource"

describe ChefDK::ChefResource::GeneratorDesc do

  let(:node) { Chef::Node.new }

  let(:stdout) { StringIO.new }

  let(:stderr) { StringIO.new }

  let(:null_formatter) { Chef::Formatters.new(:null, stdout, stderr) }

  let(:events) do
    Chef::EventDispatch::Dispatcher.new.tap do |d|
      d.register(null_formatter)
    end
  end

  let(:cookbook_collection) { Chef::CookbookCollection.new }

  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }

  let(:message) { "this part of the cookbook does a thing" }

  let(:resource) { described_class.new(message, run_context) }

  let(:provider) { resource.provider_for_action(:write) }

  describe "resource" do

    it "has the message it was created with" do
      expect(resource.message).to eq(message)
    end

    it "defaults to action :write" do
      expect(resource.action).to eq( [ :write ] )
    end

    it "is identified by the message property" do
      expect(resource.identity).to eq(message)
    end

    it "writes the message to the formatter" do
      provider.action_write
      expect(stdout.string).to include(message)
    end

  end
end
