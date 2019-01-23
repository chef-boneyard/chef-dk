#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "chef-dk/configurable"
require "chef-dk/policyfile_services/rm_policy_group"

module ChefDK
  module Command

    class DeletePolicyGroup < Base

      banner(<<~BANNER)
        Usage: chef delete-policy-group POLICY_GROUP [options]

        `chef delete-policy-group POLICY_GROUP` deletes the policy group POLICY_GROUP on
        the configured Chef Server. Policy Revisions associated to the policy group are
        not deleted. The state of the policy group will be backed up locally, allowing
        you to undo this operation via the `chef undelete` command.

        See our detailed README for more information:

        https://docs.chef.io/policyfile.html

        Options:

      BANNER

      option :config_file,
        short:        "-c CONFIG_FILE",
        long:         "--config CONFIG_FILE",
        description:  "Path to configuration file"

      option :debug,
        short:        "-D",
        long:         "--debug",
        description:  "Enable stacktraces and other debug output",
        default:      false

      include Configurable

      attr_accessor :ui

      attr_reader :policy_group

      def initialize(*args)
        super
        @policy_group = nil
        @rm_policy_group_service = nil
        @ui = UI.new
      end

      def run(params)
        return 1 unless apply_params!(params)
        rm_policy_group_service.run
        ui.msg("This operation can be reversed by running `chef undelete --last`.")
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def rm_policy_group_service
        @rm_policy_group_service ||=
          PolicyfileServices::RmPolicyGroup.new(config: chef_config,
                                                ui: ui,
                                                policy_group: policy_group)
      end

      def debug?
        !!config[:debug]
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

        if remaining_args.size == 1
          @policy_group = remaining_args.first
          true
        elsif remaining_args.empty?
          ui.err("You must specify the POLICY_GROUP to delete.")
          ui.err("")
          ui.err(opt_parser)
          false
        else
          ui.err("Too many arguments")
          ui.err("")
          ui.err(opt_parser)
          false
        end
      end

    end
  end
end
