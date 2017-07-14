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

require "chef-dk/policyfile/comparison_base"
require "chef-dk/policyfile/lister"
require "chef-dk/pager"

module ChefDK
  module PolicyfileServices
    class ShowPolicy
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

      attr_reader :policy_lister

      attr_reader :ui

      attr_reader :policy_name

      attr_reader :chef_config

      attr_reader :policy_group

      def initialize(config: nil, ui: nil, policy_name: nil, policy_group: nil, show_orphans: false, summary_diff: false, pager: false)
        @chef_config = config
        @ui = ui
        @policy_name = policy_name
        @policy_group = policy_group
        @show_orphans = show_orphans
        @summary_diff = summary_diff
        @enable_pager = pager
      end

      def run
        if show_policy_revision?
          display_policy_revision
        elsif show_all_policies?
          display_all_policies
        else
          display_single_policy
        end
        true
      rescue PolicyfileNestedException
        raise
      rescue => e
        raise PolicyfileListError.new("Failed to list policyfile data from the server", e)
      end

      def show_policy_revision?
        !!policy_group
      end

      def show_all_policies?
        !policy_name
      end

      def show_orphans?
        @show_orphans
      end

      def show_summary_diff?
        @summary_diff
      end

      def enable_pager?
        @enable_pager
      end

      def report
        @report ||= ReportPrinter.new(ui)
      end

      def policy_lister
        @policy_info_fetcher ||= Policyfile::Lister.new(config: chef_config)
      end

      def display_policy_revision
        lock = Policyfile::ComparisonBase::PolicyGroup.new(policy_group, policy_name, http_client).lock
        pager = Pager.new(enable_pager: enable_pager?)
        pager.with_pager { |p| p.ui.msg(FFI_Yajl::Encoder.encode(lock, pretty: true)) }
      end

      def display_all_policies
        if policy_lister.empty?
          ui.err("No policies or policy groups exist on the server")
          return
        end
        if policy_lister.policies_by_name.empty?
          ui.err("No policies exist on the server")
          return
        end
        policy_lister.revision_ids_by_group_for_each_policy do |policy_name, rev_id_by_group|
          report.h1(policy_name)

          if rev_id_by_group.empty?
            ui.err("Policy #{policy_name} is not assigned to any groups")
            ui.err("")
          else
            rev_ids_for_report = format_rev_ids_for_report(rev_id_by_group)
            report.table_list(rev_ids_for_report)
          end

          if show_orphans?
            orphans = policy_lister.orphaned_revisions(policy_name)

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
        rev_id_by_group = policy_lister.revision_ids_by_group_for(policy_name)

        if rev_id_by_group.empty? || rev_id_by_group.all? { |_k, rev| rev.nil? }
          ui.err("No policies named '#{policy_name}' are associated with a policy group")
          ui.err("")
        elsif show_summary_diff?
          unique_rev_ids = rev_id_by_group.unique_revision_ids
          revision_info = policy_lister.revision_info_for(policy_name, unique_rev_ids)

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
          orphans = policy_lister.orphaned_revisions(policy_name)

          unless orphans.empty?
            report.h2("Orphaned:")
            formatted_orphans = orphans.map { |id| shorten_rev_id(id) }
            report.list(formatted_orphans)
          end
        end
      end

      def shorten_rev_id(revision_id)
        revision_id[0, 10]
      end

      def http_client
        @http_client ||= Chef::ServerAPI.new(chef_config.chef_server_url,
                                             signing_key_filename: chef_config.client_key,
                                             client_name: chef_config.node_name)
      end

      private

      def format_rev_ids_for_report(rev_id_by_group)
        rev_id_by_group.format_revision_ids do |rev_id|
          rev_id ? rev_id[0, 10] : "*NOT APPLIED*"
        end
      end

    end
  end
end
