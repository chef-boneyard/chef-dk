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

require 'chef'

module ChefDK
  # An adapter to chef's APIs to kick off a chef-client run.
  class ChefRunner

    attr_reader :cookbook_path
    attr_reader :run_list

    def initialize(cookbook_path, run_list)
      @cookbook_path = cookbook_path
      @run_list = run_list
      @formatter = nil
      @ohai = nil
    end

    def converge
      configure
      Chef::Runner.new(run_context).converge
    end

    def run_context
      @run_context ||= policy.setup_run_context
    end

    def policy
      return @policy_builder if @policy_builder

      @policy_builder = Chef::PolicyBuilder::ExpandNodeObject.new("chef-dk", ohai.data, {}, nil, formatter)
      @policy_builder.load_node
      @policy_builder.build_node
      @policy_builder.node.run_list(*run_list)
      @policy_builder.expand_run_list
      @policy_builder
    end

    def formatter
      @formatter ||= Chef::Formatters.new(:doc, stdout, stderr)
    end

    def configure
      Chef::Config.solo = true
      Chef::Config.cookbook_path = cookbook_path
      Chef::Config.color = true
      Chef::Config.diff_disabled = true

      # atomic file operations on Windows require Administrator privileges to be able to read the SACL from a file
      Chef::Config.file_atomic_update = false if Chef::Platform.windows?
    end

    def ohai
      return @ohai if @ohai

      @ohai = Ohai::System.new
      @ohai.all_plugins(["platform", "platform_version"])
      @ohai
    end

    def stdout
      $stdout
    end

    def stderr
      $stderr
    end

  end
end

