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
require "chef-dk/policyfile_services/undelete"

module ChefDK
  module Command

    class Undelete < Base

      banner(<<~BANNER)
        Usage: chef undelete [--list | --id ID] [options]

        `chef undelete` helps you recover quickly if you've deleted a policy or policy
        group in error. When run with no arguements, it lists the available undo
        operations. To undo the last delete operation, use `chef undelete --last`.

        CAVEATS:
        `chef undelete` doesn't detect conflicts. If a deleted item has been recreated,
        running `chef undelete` will overwrite it.

        Undo information does not include cookbooks that might be referenced by
        policies. If you have cleaned the policy cookbooks after the delete operation
        you want to reverse, `chef undelete` may not be able to fully restore the
        previous state.

        The delete commands also do not store access control data, so you may have to
        manually reapply any ACL customizations you have made.

        See our detailed README for more information:

        https://docs.chef.io/policyfile.html

        Options:

      BANNER

      option :undo_last,
        short:        "-l",
        long:         "--last",
        description:  "Undo the most recent delete operation"

      option :undo_record_id,
        short:        "-i ID",
        long:         "--id ID",
        description:  "Undo the delete operation with the given ID"

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

      attr_reader :undo_record_id

      def initialize(*args)
        super
        @list_undo_records = false
        @undo_record_id = nil
        @ui = UI.new
      end

      def run(params)
        return 1 unless apply_params!(params)
        if list_undo_records?
          undelete_service.list
        else
          undelete_service.run
        end
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def undelete_service
        @undelete_service ||=
          PolicyfileServices::Undelete.new(config: chef_config,
                                           ui: ui,
                                           undo_record_id: undo_record_id)
      end

      def debug?
        !!config[:debug]
      end

      def list_undo_records?
        @list_undo_records
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
        elsif config[:undo_record_id].nil? && config[:undo_last].nil?
          @list_undo_records = true
          true
        elsif config[:undo_record_id] && config[:undo_last]
          ui.err("Error: options --last and --id cannot both be given.")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif config[:undo_record_id]
          @undo_record_id = config[:undo_record_id]
          true
        elsif config[:undo_last]
          @undo_record_id = nil
          true
        end
      end

    end
  end
end
