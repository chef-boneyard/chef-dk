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
require "chef-dk/configurable"
require "unit/fixtures/configurable/test_configurable"

describe ChefDK::Configurable do

  let(:includer) { TestConfigurable.new }

  it "provides chef_config" do
    expect(includer.chef_config).to eq Chef::Config
  end

  it "provides chefdk_config" do
    expect(includer.chefdk_config).to eq Chef::Config.chefdk
  end

  it "provides knife_config" do
    expect(includer.knife_config).to eq Chef::Config.knife
  end

  it "provides generator_config" do
    expect(includer.generator_config).to eq Chef::Config.chefdk.generator
  end
end
