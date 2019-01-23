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
require "chef-dk/pager"
require "chef-dk/policyfile/differ"
require "chef-dk/policyfile/comparison_base"
require "chef-dk/policyfile/storage_config"
require "chef-dk/configurable"
require "chef/server_api"

module ChefDK
  module Command

    class Diff < Base

      include Configurable
      include Policyfile::StorageConfigDelegation

      banner(<<~BANNER)
        Usage: chef diff [POLICYFILE] [--head | --git GIT_REF | POLICY_GROUP | POLICY_GROUP...POLICY_GROUP ]

        `chef diff` displays an itemized diff comparing two revisions of a
        Policyfile lock.

        When the `--git` option is given, `chef diff` either compares a given
        git reference against the current lockfile revision on disk or compares
        between two git references. Examples:

        * `chef diff --git HEAD`: compares the current lock with the latest
          commit on the current branch.
        * `chef diff --git master` compares the current lock with the latest
          commit to master.
        * `chef diff --git v1.0.0`: compares the current lock with the revision
          as of the `v1.0.0` tag.
        * `chef diff --git master...dev-branch` compares the Policyfile lock on
          master with the revision on the `dev-branch` branch.
        * `chef diff --git v1.0.0...master` compares the Policyfile lock at the
          `v1.0.0` tag with the lastest revision on the master branch.

        `chef diff --head` is a shortcut for `chef diff --git HEAD`.

        When no git-specific flag is given, `chef diff` either compares the
        current lockfile revision on disk to one on the server or compares two
        lockfiles on the server. Lockfiles on the Chef Server are specified by
        Policy Group. Examples:

        * `chef diff staging`: compares the current lock with the one currently
          assigned to the `staging` Policy Group.
        * `chef diff production...staging` compares the lock currently assigned
          to the `production` Policy Group to the lock currently assigned to the
          `staging` Policy Group.

        Options:
      BANNER

      option :git,
        short:       "-g GIT_REF",
        long:        "--git GIT_REF",
        description: "Compare local lock against GIT_REF, or between two git commits"

      option :head,
        long:        "--head",
        description: "Compare local lock against last git commit",
        boolean:     true

      option :pager,
        long:        "--[no-]pager",
        description: "Enable/disable paged diff ouput (default: enabled)",
        default:     true,
        boolean:     true

      option :config_file,
        short:       "-c CONFIG_FILE",
        long:        "--config CONFIG_FILE",
        description: "Path to configuration file"

      option :debug,
        short:       "-D",
        long:        "--debug",
        description: "Enable stacktraces and other debug output",
        default:     false

      attr_accessor :ui

      attr_reader :old_base
      attr_reader :new_base

      attr_reader :storage_config

      def initialize(*args)
        super

        @ui = UI.new

        @old_base = nil
        @new_base = nil
        @policyfile_relative_path = nil
        @storage_config = nil
        @http_client = nil

        @old_lock = nil
        @new_lock = nil
      end

      def debug?
        !!config[:debug]
      end

      def run(params = [])
        return 1 unless apply_params!(params)
        print_diff
        0
      rescue PolicyfileServiceError => e
        handle_error(e)
        1
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

      def print_diff
        # eagerly evaluate locks so we hit any errors before we've entered
        # pagerland. Also, git commands behave weirdly when run while the pager
        # is active, doing this eagerly also avoids that issue
        materialize_locks
        Pager.new(enable_pager: config[:pager]).with_pager do |pager|
          differ = differ(pager.ui)
          differ.run_report
        end
      end

      def differ(ui = self.ui())
        Policyfile::Differ.new(old_name: old_base.name,
                               old_lock: old_lock,
                               new_name: new_base.name,
                               new_lock: new_lock,
                               ui: ui)
      end

      def http_client
        @http_client ||= Chef::ServerAPI.new(chef_config.chef_server_url,
                                             signing_key_filename: chef_config.client_key,
                                             client_name: chef_config.node_name)
      end

      def old_lock
        materialize_locks unless @old_lock
        @old_lock
      end

      def new_lock
        materialize_locks unless @new_lock
        @new_lock
      end

      def policy_name
        local_lock["name"]
      end

      def local_lock
        @local_lock ||= local_lock_comparison_base.lock
      end

      # ComparisonBase for the local lockfile. This is used to get the
      # policy_name which is needed to query the server for the lockfile of a
      # particular policy_group.
      def local_lock_comparison_base
        Policyfile::ComparisonBase::Local.new(policyfile_lock_relpath)
      end

      def policyfile_lock_relpath
        storage_config.policyfile_lock_filename
      end

      def apply_params!(params)
        remaining_args = parse_options(params)

        if no_comparison_specified?(remaining_args)
          ui.err("No comparison specified")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif conflicting_args_and_opts_given?(remaining_args)
          ui.err("Conflicting arguments and options: git and Policy Group comparisons cannot be mixed")
          ui.err("")
          ui.err(opt_parser)
          false
        elsif conflicting_git_options_given?
          ui.err("Conflicting git options: --head and --git are exclusive")
          ui.err("")
          ui.err(opt_parser)

          false
        elsif config[:head]
          set_policyfile_path_from_args(remaining_args)
          @old_base = Policyfile::ComparisonBase::Git.new("HEAD", policyfile_lock_relpath)
          @new_base = Policyfile::ComparisonBase::Local.new(policyfile_lock_relpath)
          true
        elsif config[:git]
          set_policyfile_path_from_args(remaining_args)
          parse_git_comparison(config[:git])
        else
          set_policyfile_path_from_args(remaining_args)
          parse_server_comparison(remaining_args)
        end
      end

      def parse_server_comparison(args)
        comparison_string = args.last
        if comparison_string.include?("...")
          old_pgroup, new_pgroup, *extra = comparison_string.split("...")
          @old_base, @new_base = [old_pgroup, new_pgroup].map do |g|
            Policyfile::ComparisonBase::PolicyGroup.new(g, policy_name, http_client)
          end

          unless extra.empty?
            ui.err("Unable to parse policy group comparison `#{comparison_string}`. Only 2 references can be specified.")
            return false
          end
        else
          @old_base = Policyfile::ComparisonBase::PolicyGroup.new(comparison_string, policy_name, http_client)
          @new_base = Policyfile::ComparisonBase::Local.new(policyfile_lock_relpath)
        end
        true
      end

      def parse_git_comparison(git_ref)
        if git_ref.include?("...")
          old_ref, new_ref, *extra = git_ref.split("...")
          @old_base, @new_base = [old_ref, new_ref].map do |r|
            Policyfile::ComparisonBase::Git.new(r, policyfile_lock_relpath)
          end

          unless extra.empty?
            ui.err("Unable to parse git comparison `#{git_ref}`. Only 2 references can be specified.")
            return false
          end
        else
          @old_base = Policyfile::ComparisonBase::Git.new(git_ref, policyfile_lock_relpath)
          @new_base = Policyfile::ComparisonBase::Local.new(policyfile_lock_relpath)
        end
        true
      end

      def no_comparison_specified?(args)
        !policy_group_comparison?(args) && !config[:head] && !config[:git]
      end

      def conflicting_args_and_opts_given?(args)
        (config[:git] || config[:head]) && policy_group_comparison?(args)
      end

      def conflicting_git_options_given?
        config[:git] && config[:head]
      end

      def comparing_policy_groups?
        !(config[:git] || config[:head])
      end

      # Try to detect if the only argument given is a policyfile path. This is
      # necessary because we support an optional argument with the path to the
      # ruby policyfile. It would be easier if we used an option like `-f`, but
      # that would be inconsistent with other commands (`chef install`, `chef
      # push`, etc.).
      def policy_group_comparison?(args)
        return false if args.empty?
        return true if args.size > 1
        !(args.first =~ /\.rb\Z/)
      end

      def set_policyfile_path_from_args(args)
        policyfile_relative_path =
          if !comparing_policy_groups?
            args.first || "Policyfile.rb"
          elsif args.size == 1
            "Policyfile.rb"
          else
            args.first
          end
        @storage_config = Policyfile::StorageConfig.new.use_policyfile(policyfile_relative_path)
      end

      def materialize_locks
        @old_lock = old_base.lock
        @new_lock = new_base.lock
      end

    end

  end
end
