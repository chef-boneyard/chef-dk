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
require "chef-dk/policyfile/lister"
require "chef-dk/policyfile_services/show_policy"

module ChefDK
  module Command

    class ShowPolicy < Base

      banner(<<~BANNER)
        Usage: chef show-policy [POLICY_NAME [POLICY_GROUP]] [options]

        `chef show-policy` Displays the revisions of policyfiles on the server. By
        default, only active policy revisions are shown. Use the `--orphans` options to
        show policy revisions that are not assigned to any policy group.

        When both POLICY_NAME and POLICY_GROUP are given, the command shows the content
        of a the active policyfile lock for the given POLICY_GROUP. See also the `diff`
        command.

        See our detailed README for more information:

        https://docs.chef.io/policyfile.html

        Options:

      BANNER

      option :show_orphans,
        short:        "-o",
        long:         "--orphans",
        description:  "Show policy revisions that are unassigned",
        default:      false

      option :pager,
        long:        "--[no-]pager",
        description: "Enable/disable paged policyfile lock ouput (default: enabled)",
        default:     true,
        boolean:     true

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

      attr_reader :policy_name

      attr_reader :policy_group

      def initialize(*args)
        super
        @show_all_policies = nil
        @policy_name = nil
        @policy_group = nil
        @ui = UI.new
      end

      def run(params)
        return 1 unless apply_params!(params)
        show_policy_service.run
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def show_policy_service
        @policy_list_service ||=
          PolicyfileServices::ShowPolicy.new(config: chef_config,
                                             ui: ui,
                                             policy_name: policy_name,
                                             policy_group: policy_group,
                                             show_orphans: show_orphans?,
                                             summary_diff: show_summary_diff?,
                                             pager: enable_pager?)
      end

      def debug?
        !!config[:debug]
      end

      def show_summary_diff?
        false
      end

      def show_orphans?
        config[:show_orphans]
      end

      def enable_pager?
        config[:pager]
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

        if remaining_args.empty? && show_summary_diff?
          ui.err("The --summary-diff option can only be used when showing a single policy")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif remaining_args.empty?
          @show_all_policies = true
          true
        elsif remaining_args.size == 1
          @policy_name = remaining_args.first
          @show_all_policies = false
          true
        elsif remaining_args.size == 2
          @policy_name = remaining_args[0]
          @policy_group = remaining_args[1]
          @show_all_policies = false
          true
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
