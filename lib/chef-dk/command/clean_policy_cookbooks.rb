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
require "chef-dk/policyfile_services/clean_policy_cookbooks"

module ChefDK
  module Command

    class CleanPolicyCookbooks < Base

      banner(<<~BANNER)
        Usage: chef clean-policy-cookbooks [options]

        `chef clean-policy-cookbooks` deletes unused policyfile cookbooks. Cookbooks
        are considered unused when they are not referenced by any policyfile revision
        on the server. Note that cookbooks which are referenced by "orphaned" policy
        revisions are not removed, so you may wish to run `chef clean-policy-revisions`
        to remove orphaned policies before running this command.

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

        @clean_policy_cookbooks_service = nil
      end

      def run(params)
        return 1 unless apply_params!(params)
        clean_policy_cookbooks_service.run
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def clean_policy_cookbooks_service
        @clean_policy_cookbooks_service ||=
          PolicyfileServices::CleanPolicyCookbooks.new(config: chef_config, ui: ui)
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
