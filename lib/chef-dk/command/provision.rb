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

require "ostruct"

require "chef-dk/command/base"
require "chef-dk/configurable"
require "chef-dk/chef_runner"
require "chef-dk/policyfile_services/push"

require "chef/provisioning"

module ChefDK

  module ProvisioningData

    def self.reset
      @context = nil
    end

    def self.context
      @context ||= Context.new
    end

    class Context

      attr_accessor :action

      attr_accessor :node_name

      attr_accessor :target

      attr_accessor :enable_policyfile

      attr_accessor :policy_group

      attr_accessor :policy_name

      attr_accessor :extra_chef_config

      attr_accessor :opts

      def initialize
        @extra_chef_config = ""
        @opts = nil
      end

      def set_user_opts(hash)
        @opts = OpenStruct.new(hash)
      end

      def convergence_options
        {
          chef_server: Chef::Config.chef_server_url,
          chef_config: chef_config,
        }
      end

      def chef_config
        config = <<-CONFIG
# SSL Settings:
ssl_verify_mode #{Chef::Config.ssl_verify_mode.inspect}

CONFIG
        if enable_policyfile
          policyfile_config = <<-CONFIG
# Policyfile Settings:
use_policyfile true
policy_document_native_api true

policy_group "#{policy_group}"
policy_name "#{policy_name}"

CONFIG
          config << policyfile_config
        end

        config << extra_chef_config.to_s
        config
      end

    end
  end

  module Command

    class Provision < Base

      banner(<<-E)
Usage: chef provision POLICY_GROUP --policy-name POLICY_NAME [options]
       chef provision POLICY_GROUP --sync [POLICYFILE_PATH] [options]
       chef provision --no-policy [options]

`chef provision` invokes an embedded chef-client run to provision machines
using Chef Provisioning. If not otherwise specified, `chef provision` will
expect to find a cookbook named 'provision' in the current working directory.
It runs a recipe in this cookbook which should use Chef Provisioning to create
one or more machines (or other infrastructure).

`chef provision` provides three forms of operation:

### chef provision POLICY_GROUP --policy-name POLICY_NAME

In the first form of the command, `chef provision` creates machines that will
operate in policyfile mode. The chef configuration passed to the cookbook will
set the policy group and policy name as given.

### chef provision POLICY_GROUP --sync [POLICYFILE_PATH] [options]

In the second form of the command, `chef provision` create machines that will
operate in policyfile mode and syncronizes a local policyfile to the server
before converging the machine(s) defined in the provision cookbook.

### chef provision --no-policy [options]

In the third form of the command, `chef provision` expects to create machines
that will not operate in policyfile mode.

Chef Provisioning is documented at https://docs.chef.io/provisioning.html

Options:

E
      include Configurable

      option :config_file,
        short:        "-c CONFIG_FILE",
        long:         "--config CONFIG_FILE",
        description:  "Path to configuration file"

      option :policy_name,
        short:        "-p POLICY_NAME",
        long:         "--policy-name POLICY_NAME",
        description:  "Set the default policy name for provisioned machines"

      option :sync,
        short:        "-s [POLICYFILE_PATH]",
        long:         "--sync [POLICYFILE_PATH]",
        description:  "Push policyfile to the server before converging node(s)"

      option :enable_policyfile,
        long:         "--[no-]policy",
        description:  "Enable/disable policyfile integration (defaults to enabled, use --no-policy to disable)",
        default:      true

      option :destroy,
        short:        "-d",
        long:         "--destroy",
        description:  "Set default machine action to :destroy",
        default:      false,
        boolean:      true

      option :machine_recipe,
        short:        "-r RECIPE",
        long:         "--recipe RECIPE",
        description:  "Machine recipe to use",
        default:      "default"

      option :cookbook,
        long:         "--cookbook COOKBOOK_PATH",
        description:  "Path to your provisioning cookbook",
        default:      "./provision"

      option :node_name,
        short:        "-n NODE_NAME",
        long:         "--node-name NODE_NAME",
        description:  "Set default node name (may be overriden by provisioning cookbook)"

      option :target,
        short:        "-t REMOTE_HOST",
        long:         "--target REMOTE_HOST",
        description:  "Set hostname or IP of the host to converge (may be overriden by provisioning cookbook)"

      OPT_SEPARATOR = /[=\s]+/

      def self.split_opt(key_value)
        key, _separator, value = key_value.partition(OPT_SEPARATOR)
        [key, value]
      end

      opts = {}

      option :opts,
        short:        "-o OPT=VALUE",
        long:         "--opt OPT=VALUE",
        description:  "Set arbitrary option OPT on the provisioning context",
        proc:         lambda { |arg| key, value = split_opt(arg); opts[key] = value; opts },
        default:      {}

      option :debug,
        short:       "-D",
        long:        "--debug",
        description: "Enable stacktraces and other debug output",
        default:     false

      attr_reader :params
      attr_reader :policyfile_relative_path
      attr_reader :policy_group

      attr_accessor :ui

      def initialize(*args)
        super

        @ui = UI.new

        @policyfile_relative_path = nil
        @policy_group = nil

        @provisioning_cookbook_path = nil
        @provisioning_cookbook_name = nil
      end

      def run(params = [])
        return 1 unless apply_params!(params)
        chef_config # force chef config to load
        return 1 unless check_cookbook_and_recipe_path

        push.run if sync_policy?

        setup_context

        chef_runner.converge
        0
      rescue ChefRunnerError, PolicyfileServiceError => e
        handle_error(e)
        1
        # Chef Provisioning doesn't fail gracefully when a driver is missing:
        # https://github.com/chef/chef-provisioning/issues/338
      rescue StandardError, LoadError => error
        ui.err("Error: #{error.message}")
        1
      end

      # An instance of ChefRunner. Calling ChefRunner#converge will trigger
      # convergence and generate the desired code.
      def chef_runner
        @chef_runner ||= ChefRunner.new(provisioning_cookbook_path, ["recipe[#{provisioning_cookbook_name}::#{recipe}]"])
      end

      def push
        @push ||= PolicyfileServices::Push.new(policyfile: policyfile_relative_path,
                                               ui: ui,
                                               policy_group: policy_group,
                                               config: chef_config,
                                               root_dir: Dir.pwd)
      end

      def setup_context
        ProvisioningData.context.tap do |c|

          c.action = default_action
          c.node_name = node_name
          c.target = target

          c.set_user_opts(user_opts)

          c.enable_policyfile = enable_policyfile?

          if enable_policyfile?
            c.policy_group = policy_group
            c.policy_name = policy_name
          end

        end
      end

      def policy_name
        if sync_policy?
          push.policy_data["name"]
        else
          config[:policy_name]
        end
      end

      def default_action
        if config[:destroy]
          :destroy
        else
          :converge
        end
      end

      def node_name
        config[:node_name]
      end

      def target
        config[:target]
      end

      def user_opts
        config[:opts]
      end

      def recipe
        config[:machine_recipe]
      end

      # Gives the `cookbook_path` in the chef-client sense, which is the
      # directory that contains the provisioning cookbook.
      def provisioning_cookbook_path
        detect_provisioning_cookbook_name_and_path! unless @provisioning_cookbook_path
        @provisioning_cookbook_path
      end

      # The name of the provisioning cookbook
      def provisioning_cookbook_name
        detect_provisioning_cookbook_name_and_path! unless @provisioning_cookbook_name
        @provisioning_cookbook_name
      end

      def cookbook_path
        config[:cookbook]
      end

      def enable_policyfile?
        config[:enable_policyfile]
      end

      def apply_params!(params)
        remaining_args = parse_options(params)
        if enable_policyfile?
          handle_policy_argv(remaining_args)
        else
          handle_no_policy_argv(remaining_args)
        end
      end

      def debug?
        !!config[:debug]
      end

      def sync_policy?
        config.key?(:sync)
      end

      private

      def detect_provisioning_cookbook_name_and_path!
        given_path = File.expand_path(cookbook_path, Dir.pwd)
        @provisioning_cookbook_name = File.basename(given_path)
        @provisioning_cookbook_path = File.dirname(given_path)
      end

      def check_cookbook_and_recipe_path
        if !File.exist?(cookbook_expanded_path)
          ui.err("ERROR: Provisioning cookbook not found at path #{cookbook_expanded_path}")
          false
        elsif !File.exist?(provisioning_recipe_path)
          ui.err("ERROR: Provisioning recipe not found at path #{provisioning_recipe_path}")
          false
        else
          true
        end
      end

      def provisioning_recipe_path
        File.join(cookbook_expanded_path, "recipes", "#{recipe}.rb")
      end

      def cookbook_expanded_path
        File.join(chef_runner.cookbook_path, provisioning_cookbook_name)
      end

      def handle_no_policy_argv(remaining_args)
        if remaining_args.empty?
          true
        else
          ui.err("The --no-policy flag cannot be combined with policyfile arguments")
          ui.err("")
          ui.err(opt_parser)
          false
        end
      end

      def handle_policy_argv(remaining_args)
        if remaining_args.size > 1
          ui.err("Too many arguments")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif remaining_args.size < 1
          ui.err("You must specify a POLICY_GROUP or disable policyfiles with --no-policy")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif !sync_policy? && config[:policy_name].nil?
          ui.err("You must pass either --sync or --policy-name to provision machines in policyfile mode")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif sync_policy? && config[:policy_name]
          ui.err("The --policy-name and --sync arguments cannot be combined")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif sync_policy?
          @policy_group = remaining_args[0]
          @policyfile_relative_path = config[:sync]
          true
        elsif config[:policy_name]
          @policy_group = remaining_args[0]
          true
        else
          raise BUG, "Cannot properly parse input argv '#{ARGV.inspect}'"
        end
      end

      def handle_error(error)
        ui.err("Error: #{error.message}")
        if error.respond_to?(:reason)
          ui.err("Reason: #{error.reason}")
          ui.err("")
          ui.err(error.extended_error_info) if debug?
          ui.err(error.cause.backtrace.join("\n")) if debug?
        end
      end

    end
  end
end
