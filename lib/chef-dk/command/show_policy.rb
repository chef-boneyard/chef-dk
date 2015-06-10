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

require 'chef-dk/command/base'
require 'chef-dk/ui'
require 'chef-dk/configurable'
require 'chef-dk/policyfile/lister'
require 'chef-dk/policyfile_services/show_policy'

module ChefDK
  module Command


    class ShowPolicy < Base

      banner(<<-BANNER)
Usage: chef show-policy [POLICY_NAME] [options]

`chef show-policy` Displays the revisions of policyfiles on the server. By
default, only active policy revisions are shown. Use the `--orphans` options to
show policy revisions that are not assigned to any policy group.

The Policyfile feature is incomplete and beta quality. See our detailed README
for more information.

https://github.com/opscode/chef-dk/blob/master/POLICYFILE_README.md

Options:

BANNER

      option :summary_diff,
        short:        "-s",
        long:         "--summary-diff",
        description:  "Summarize differences in policy revisions",
        default:      false

      option :show_orphans,
        short:        "-o",
        long:         "--orphans",
        description:  "Show policy revisions that are unassigned",
        default:      false

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

      def initialize(*args)
        super
        @show_all_policies = nil
        @policy_name = nil
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
                                             show_all: show_all_policies?,
                                             ui: ui,
                                             policy_name: policy_name,
                                             show_orphans: show_orphans?,
                                             summary_diff: show_summary_diff?)
      end

      def debug?
        !!config[:debug]
      end

      def show_all_policies?
        @show_all_policies
      end

      def show_summary_diff?
        !!config[:summary_diff]
      end

      def show_orphans?
        config[:show_orphans]
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
          @policy_name = nil
          @show_all_policies = true
          true
        elsif remaining_args.size == 1
          @policy_name = remaining_args.first
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

