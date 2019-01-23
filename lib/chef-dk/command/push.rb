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

require "chef-dk/command/base"
require "chef-dk/ui"
require "chef-dk/policyfile_services/push"
require "chef-dk/configurable"

module ChefDK
  module Command

    class Push < Base

      include Configurable

      banner(<<~E)
        Usage: chef push POLICY_GROUP [ POLICY_FILE ] [options]

        `chef push` Uploads an existing Policyfile.lock.json to a Chef Server, along
        with all the cookbooks contained in the policy lock. The policy lock is applied
        to a specific POLICY_GROUP, which is a set of nodes that share the same
        run_list and cookbooks.

        See our detailed README for more information:

        https://docs.chef.io/policyfile.html

        Options:

      E

      option :config_file,
        short:       "-c CONFIG_FILE",
        long:        "--config CONFIG_FILE",
        description: "Path to configuration file"

      option :debug,
        short:       "-D",
        long:        "--debug",
        description: "Enable stacktraces and other debug output",
        default:     false

      attr_reader :policyfile_relative_path
      attr_reader :policy_group

      attr_accessor :ui

      def initialize(*args)
        super
        @push = nil
        @ui = nil
        @policy_group = nil
        @policyfile_relative_path = nil
        @chef_config = nil
        @ui = UI.new
      end

      def run(params = [])
        return 1 unless apply_params!(params)
        push.run
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def debug?
        !!config[:debug]
      end

      def push
        @push ||= PolicyfileServices::Push.new(policyfile: policyfile_relative_path,
                                               ui: ui,
                                               policy_group: policy_group,
                                               config: chef_config,
                                               root_dir: Dir.pwd)
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

      def apply_params!(params)
        remaining_args = parse_options(params)
        if remaining_args.size < 1 || remaining_args.size > 2
          ui.err(opt_parser)
          return false
        else
          @policy_group = remaining_args[0]
          @policyfile_relative_path = remaining_args[1]
        end
        true
      end

    end
  end
end
