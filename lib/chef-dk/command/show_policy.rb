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
require 'set'

module ChefDK
  module Command

    class RevIDLockDataMap

      attr_reader :policy_name
      attr_reader :lock_info_by_rev_id

      def initialize(policy_name, lock_info_by_rev_id)
        @policy_name = policy_name
        @lock_info_by_rev_id = lock_info_by_rev_id
      end


      def cb_info_for(rev_id, cookbook_name)
        lock = lock_info_by_rev_id[rev_id]
        cookbook_lock = lock["cookbook_locks"][cookbook_name]

        if cookbook_lock
          [cookbook_lock["version"], cookbook_lock["identifier"] ]
        else
          nil
        end
      end

      def cbs_with_differing_ids
        cbs_with_differing_ids = Set.new
        all_cookbook_names.each do |cookbook_name|
          all_identifiers = lock_info_by_rev_id.inject(Set.new) do |id_set, (_rev_id, rev_info)|
            cookbook_lock = rev_info["cookbook_locks"][cookbook_name]
            identifier = cookbook_lock && cookbook_lock["identifier"]
            id_set << identifier
          end
          cbs_with_differing_ids << cookbook_name if all_identifiers.size > 1
        end
        cbs_with_differing_ids
      end

      def all_cookbook_names
        lock_info_by_rev_id.inject(Set.new) do |cb_set, (_rev_id, rev_info)|
          cb_set.merge(rev_info["cookbook_locks"].keys)
        end
      end
    end

    class PolicyGroupRevIDMap

      attr_reader :policy_name
      attr_reader :revision_ids_by_group

      def initialize(policy_name, revision_ids_by_group)
        @policy_name = policy_name
        @revision_ids_by_group = revision_ids_by_group
      end

      def unique_revision_ids
        revision_ids_by_group.values.uniq
      end

      def policy_group_names
        revision_ids_by_group.keys
      end

      def max_group_name_length
        policy_group_names.map(&:size).max
      end

      def format_revision_ids
        revision_ids_by_group.inject({}) do |map, (group_name, rev_id)|
          map[group_name] = yield rev_id
          map
        end
      end

      def empty?
        policy_group_names.empty?
      end

      def each
        revision_ids_by_group.each do |group_name, rev_id|
          yield group_name, rev_id
        end
      end
    end

    class PolicyInfoFetcher

      attr_accessor :policies_by_name

      # A Hash with the following format:
      #   "dev" => {
      #     "appserver" => "1111111111111111111111111111111111111111111111111111111111111111",
      #     "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
      #     "db" => "9999999999999999999999999999999999999999999999999999999999999999"
      #   }
      attr_accessor :policies_by_group

      attr_accessor :policy_lock_content

      def initialize
        @policies_by_name = {}
        @policies_by_group = {}
        @policy_lock_content = {}
        @active_revisions = nil
      end

      def set!(policies_by_name, policies_by_group)
        @policies_by_name = policies_by_name
        @policies_by_group = policies_by_group
        @active_revisions = nil
      end

      def revision_info_for(policy_name, _revision_id_list)
        RevIDLockDataMap.new(policy_name, policy_lock_content[policy_name])
      end

      def revision_ids_by_group_for_each_policy
        policies_by_name.each do |policy_name, _policies|
          rev_id_by_group = revision_ids_by_group_for(policy_name)
          yield policy_name, rev_id_by_group
        end
      end

      def revision_ids_by_group_for(policy_name)
        map = policies_by_group.inject({}) do |rev_id_map, (group_name, rev_id_map_for_group)|
          rev_id_map[group_name] = rev_id_map_for_group[policy_name]
          rev_id_map
        end
        PolicyGroupRevIDMap.new(policy_name, map)
      end

      def orphaned_revisions(policy_name)
        orphans = []
        policies_by_name[policy_name].each do |rev_id, _data|
          orphans << rev_id unless active_revisions.include?(rev_id)
        end
        orphans
      end

      def active_revisions
        @active_revisions ||= policies_by_group.inject(Set.new) do |set, (_group, policy_name_rev_id_map)|
          policy_name_rev_id_map.each do |policy_name, rev_id|
            set << rev_id
          end
          set
        end
      end

      def empty?
        policies_by_name.empty? && policies_by_group.empty?
      end

    end

    class ReportPrinter

      attr_reader :ui

      def initialize(ui)
        @ui = ui
      end

      def h1(heading)
        ui.msg(heading)
        ui.msg("=" * heading.size)
        ui.msg("")
      end

      def h2(heading)
        ui.msg(heading)
        ui.msg("-" * heading.size)
        ui.msg("")
      end

      def table_list(items)
        left_justify_size = items.keys.map(&:size).max.to_i + 2
        items.each do |name, value|
          justified_name = "#{name}:".ljust(left_justify_size)
          ui.msg("* #{justified_name} #{value}")
        end

        ui.msg("")
      end

      def list(items)
        items.each { |item| ui.msg("* #{item}") }
        ui.msg("")
      end
    end

    class ShowPolicy < Base

      # TODO: banner

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

      def report
        @report ||= ReportPrinter.new(ui)
      end

      def run(params)
        return 1 unless apply_params!(params)

        if show_all_policies?
          display_all_policies
        else
          display_single_policy
        end

        0
      end

      def display_all_policies
        if policy_info_fetcher.empty?
          ui.err("No policies or policy groups exist on the server")
          return
        end
        if policy_info_fetcher.policies_by_name.empty?
          ui.err("No policies exist on the server")
          return
        end
        policy_info_fetcher.revision_ids_by_group_for_each_policy do |policy_name, rev_id_by_group|
          report.h1(policy_name)

          if rev_id_by_group.empty?
            ui.err("Policy #{policy_name} is not assigned to any groups")
            ui.err("")
          else
            rev_ids_for_report = format_rev_ids_for_report(rev_id_by_group)
            report.table_list(rev_ids_for_report)
          end

          if show_orphans?
            orphans = policy_info_fetcher.orphaned_revisions(policy_name)

            unless orphans.empty?
              report.h2("Orphaned:")
              formatted_orphans = orphans.map { |id| shorten_rev_id(id) }
              report.list(formatted_orphans)
            end
          end
        end
      end

      def display_single_policy
        report.h1(policy_name)
        rev_id_by_group = policy_info_fetcher.revision_ids_by_group_for(policy_name)

        if rev_id_by_group.empty?
          ui.err("No policies named '#{policy_name}' are associated with a policy group")
          ui.err("")
        elsif show_summary_diff?
          unique_rev_ids = rev_id_by_group.unique_revision_ids
          revision_info = policy_info_fetcher.revision_info_for(policy_name, unique_rev_ids)

          ljust_size = rev_id_by_group.max_group_name_length + 2

          cbs_with_differing_ids = revision_info.cbs_with_differing_ids

          rev_id_by_group.each do |group_name, rev_id|
            heading = "#{group_name}:".ljust(ljust_size) + shorten_rev_id(rev_id)
            report.h2(heading)

            differing_cbs_version_info = cbs_with_differing_ids.inject({}) do |cb_version_info, cb_name|

              version, identifier = revision_info.cb_info_for(rev_id, cb_name)

              cb_info_for_report =
                if !version.nil?
                  "#{version} (#{shorten_rev_id(identifier)})"
                else
                  "*NONE*"
                end

              cb_version_info[cb_name] = cb_info_for_report

              cb_version_info
            end

            report.table_list(differing_cbs_version_info)
          end

        else
          rev_ids_for_report = format_rev_ids_for_report(rev_id_by_group)
          report.table_list(rev_ids_for_report)
        end

        if show_orphans?
          orphans = policy_info_fetcher.orphaned_revisions(policy_name)

          unless orphans.empty?
            report.h2("Orphaned:")
            formatted_orphans = orphans.map { |id| shorten_rev_id(id) }
            report.list(formatted_orphans)
          end
        end
      end

      def shorten_rev_id(revision_id)
        revision_id[0,10]
      end

      def policy_info_fetcher
        @policy_info_fetcher ||= PolicyInfoFetcher.new
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

      private

      def format_rev_ids_for_report(rev_id_by_group)
        rev_id_by_group.format_revision_ids do |rev_id|
          rev_id ? rev_id[0,10] : "*NOT APPLIED*"
        end
      end

    end
  end
end

