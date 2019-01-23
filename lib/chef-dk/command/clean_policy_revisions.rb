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
require "chef-dk/policyfile_services/clean_policies"

module ChefDK
  module Command

    class CleanPolicyRevisions < Base

      banner(<<~BANNER)
        Usage: chef clean-policy-revisions [options]

        `chef clean-policy-revisions` deletes orphaned policyfile revisions from the Chef
        Server. Orphaned policyfile revisions are not associated to any group, and
        therefore not in active use by any nodes. To list orphaned policyfile revisions
        before deleting them, use `chef show-policy --orphans`.

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

      attr_reader :policy_name

      attr_reader :policy_group

      def initialize(*args)
        super
        @ui = UI.new
      end

      def run(params)
        return 1 unless apply_params!(params)
        clean_policies_service.run
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def clean_policies_service
        @policy_list_service ||=
          PolicyfileServices::CleanPolicies.new(config: chef_config, ui: ui)
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

        if !remaining_args.empty?
          ui.err("Too many arguments")
          ui.err("")
          ui.err(opt_parser)
          false
        else
          true
        end
      end

    end
  end
end
