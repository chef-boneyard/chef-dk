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

require 'chef-dk/command/base'
require 'chef-dk/ui'
require 'chef-dk/policyfile_services/install'
require 'chef-dk/policyfile_services/update_attributes'

module ChefDK
  module Command

    class Update < Base

      banner(<<-BANNER)
Usage: chef update [ POLICY_FILE ] [options]

`chef update` reads your `Policyfile.rb`, applies any changes, re-solves the
dependencies and emits an updated `Policyfile.lock.json`. The new locked policy
will reflect any changes to the `run_list` and pull in any cookbook updates
that are compatible with the version constraints stated in your `Policyfile.rb`.

NOTE: `chef update` does not yet support granular updates (e.g., just updating
the `run_list` or a specific cookbook version). Support will be added in a
future version.

The Policyfile feature is incomplete and beta quality. See our detailed README
for more information.

https://github.com/opscode/chef-dk/blob/master/POLICYFILE_README.md

Options:

BANNER

      option :debug,
        short:        "-D",
        long:         "--debug",
        description:  "Enable stacktraces and other debug output",
        default:      false,
        boolean:      true

      option :update_attributes,
        short:        "-a",
        long:         "--attributes",
        description:  "Update attributes",
        default:      false,
        boolean:      true

      attr_reader :policyfile_relative_path

      attr_accessor :ui

      def initialize(*args)
        super
        @ui = UI.new

        @policyfile_relative_path = nil
        @installer = nil
        @attributes_updater = nil
      end

      def run(params = [])
        return 1 unless apply_params!(params)
        if update_attributes?
          attributes_updater.run
        else
          installer.run
        end
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
      end

      def installer
        @installer ||= PolicyfileServices::Install.new(policyfile: policyfile_relative_path, ui: ui, root_dir: Dir.pwd, overwrite: true)
      end

      def attributes_updater
        @attributes_updater ||=
          PolicyfileServices::UpdateAttributes.new(policyfile: policyfile_relative_path, ui: ui, root_dir: Dir.pwd)
      end

      def debug?
        !!config[:debug]
      end

      def update_attributes?
        !!config[:update_attributes]
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
        if remaining_args.size > 1
          ui.err(opt_parser)
          false
        else
          @policyfile_relative_path = remaining_args.first
          true
        end
      end

    end
  end
end

