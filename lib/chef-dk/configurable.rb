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

require "chef/config"
require "chef/workstation_config_loader"

# Define a config context for ChefDK
class Chef::Config

  default(:policy_document_native_api, true)

  config_context(:chefdk) do

    # Error when we encounter unknown keys. This makes it clear to the user if
    # they get the name of the config key wrong (e.g., `chefdk.generator`
    # instead of `chefdk.generator_cookbook`).
    config_strict_mode(true)

    default(:generator_cookbook, File.expand_path("../skeletons/code_generator", __FILE__))

    config_context(:generator) do
      config_strict_mode(true)
      configurable :copyright_holder
      configurable :email
      configurable :license
    end
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

    def generator_config
      chefdk_config.generator
    end

    def knife_config
      chef_config.knife
    end
  end
end
