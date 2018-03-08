#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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

require "chef-dk/exceptions"
require "chef-dk/service_exceptions"
require "chef/policy_builder/dynamic"
require "chef"

require "chef-dk/command/generator_commands/chef_exts/quieter_doc_formatter"
require "chef-dk/command/generator_commands/chef_exts/recipe_dsl_ext"

module ChefDK

  # An adapter to chef's APIs to kick off a chef-client run.
  class ChefRunner

    attr_reader :cookbook_path
    attr_reader :run_list

    def initialize(cookbook_path, run_list)
      @cookbook_path = File.expand_path(cookbook_path)
      @run_list = run_list
      @formatter = nil
      @ohai = nil
    end

    def converge
      configure
      Chef::Runner.new(run_context).converge
    rescue Chef::Exceptions::CookbookNotFound => e
      message = "Could not find cookbook(s) to satisfy run list #{run_list.inspect} in #{cookbook_path}"
      raise CookbookNotFound.new(message, e)
    rescue => e
      raise ChefConvergeError.new("Chef failed to converge: #{e} from file #{e.backtrace.first}", e)
    end

    def run_context
      @run_context ||= policy.setup_run_context
    end

    def policy
      return @policy_builder if @policy_builder

      @policy_builder = Chef::PolicyBuilder::Dynamic.new("chef-dk", ohai.data, {}, nil, event_dispatcher)
      @policy_builder.load_node
      @policy_builder.build_node
      @policy_builder.node.run_list(*run_list)
      @policy_builder.expand_run_list
      @policy_builder
    end

    def event_dispatcher
      @event_dispatcher ||=
        Chef::EventDispatch::Dispatcher.new.tap do |d|
          d.register(doc_formatter)
        end
    end

    def doc_formatter
      Chef::Formatters.new(:chefdk_doc, stdout, stderr)
    end

    def configure
      Chef::Config.solo_legacy_mode = true
      Chef::Config.cookbook_path = cookbook_path
      Chef::Config.color = true
      Chef::Config.diff_disabled = true

      # If the user has set policyfile configuration in the workstation config
      # file, the underlying chef-client code may enable policyfile mode and
      # then fail because chef-solo doesn't support policyfiles.
      Chef::Config.use_policyfile = false
      Chef::Config.policy_name = nil
      Chef::Config.policy_group = nil
      Chef::Config.deployment_group = nil

      # atomic file operations on Windows require Administrator privileges to be able to read the SACL from a file
      # Using file_staging_uses_destdir(true) will get us inherited permissions indirectly on tempfile creation
      Chef::Config.file_atomic_update = false if Chef::Platform.windows?
      Chef::Config.file_staging_uses_destdir = true # Default in Chef 12+
    end

    def ohai
      return @ohai if @ohai

      @ohai = Ohai::System.new
      @ohai.all_plugins(%w{platform platform_version})
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
