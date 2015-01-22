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

require 'chef/config'
require 'chef/workstation_config_loader'

# Define a config context for ChefDK
class Chef::Config

  default(:policy_document_native_api, false)

  config_context(:chefdk) do

    default(:generator_cookbook, File.expand_path("../skeletons/code_generator", __FILE__))

  end
end

module ChefDK
  module Configurable

    def chef_config
      return @chef_config if @chef_config
      config_loader.load
      @chef_config = Chef::Config
    end

    def chefdk_config
      chef_config.chefdk
    end

    def config_loader
      @config_loader ||= Chef::WorkstationConfigLoader.new(config[:config_file])
    end

  end
end

