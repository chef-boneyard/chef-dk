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

require "diff/lcs"
require "diff/lcs/hunk"
require "paint"
require "ffi_yajl"

module ChefDK
  module Policyfile
    class Differ

      POLICY_SECTIONS = %w{ revision_id run_list named_run_lists cookbook_locks default_attributes override_attributes }.freeze
      LINES_OF_CONTEXT = 3
      INITIAL_FILE_LENGTH_DIFFERENCE = 0
      FORMAT = :unified

      attr_reader :old_lock
      attr_reader :old_name
      attr_reader :new_lock
      attr_reader :new_name
      attr_reader :ui

      def initialize(old_name: nil, old_lock: nil, new_name: nil, new_lock: nil, ui: nil)
        @old_lock = old_lock
        @new_lock = new_lock
        @old_name = old_name
        @new_name = new_name
        @ui = ui

        @added_cookbooks    = nil
        @removed_cookbooks  = nil
        @modified_cookbooks = nil
      end

      def lock_name
        old_lock["name"]
      end

      def old_cookbook_locks
        old_lock["cookbook_locks"]
      end

      def new_cookbook_locks
        new_lock["cookbook_locks"]
      end

      def updated_sections
        @updated_sections ||= POLICY_SECTIONS.select do |key|
          old_lock[key] != new_lock[key]
        end
      end

      def different?
        !updated_sections.empty?
      end

      def run_report
        unless different?
          ui.err("No changes for policy lock '#{lock_name}' between '#{old_name}' and '#{new_name}'")
          return true
        end

        ui.print("Policy lock '#{lock_name}' differs between '#{old_name}' and '#{new_name}':\n\n")

        report_rev_id_changes
        report_run_list_changes
        report_added_cookbooks
        report_removed_cookbooks
        report_modified_cookbooks
        report_default_attribute_changes
        report_override_attribute_changes
      end

      def report_rev_id_changes
        h1("REVISION ID CHANGED")
        old_rev = old_lock["revision_id"]
        new_rev = new_lock["revision_id"]
        diff_lines([ old_rev ], [ new_rev ])
      end

      def report_run_list_changes
        return nil unless updated_sections.include?("run_list")
        h1("RUN LIST CHANGED")

        old_run_list = old_lock["run_list"]
        new_run_list = new_lock["run_list"]

        diff_lines(old_run_list, new_run_list)
      end

      def report_removed_cookbooks
        return nil if removed_cookbooks.empty?
        h1("REMOVED COOKBOOKS")
        removed_cookbooks.each do |cb_name|
          ui.print("\n")
          old_lock = pretty_json(old_cookbook_locks[cb_name])
          new_lock = []
          h2(cb_name)
          diff_lines(old_lock, new_lock)
        end
      end

      def report_added_cookbooks
        return nil if added_cookbooks.empty?
        h1("ADDED COOKBOOKS")
        added_cookbooks.each do |cb_name|
          ui.print("\n")
          old_lock = []
          new_lock = pretty_json(new_cookbook_locks[cb_name])
          h2(cb_name)
          diff_lines(old_lock, new_lock)
        end
      end

      def report_modified_cookbooks
        return nil if modified_cookbooks.empty?
        h1("MODIFIED COOKBOOKS")
        modified_cookbooks.each do |cb_name|
          ui.print("\n")
          old_lock = pretty_json(old_cookbook_locks[cb_name])
          new_lock = pretty_json(new_cookbook_locks[cb_name])
          h2(cb_name)
          diff_lines(old_lock, new_lock)
        end
      end

      def report_default_attribute_changes
        return nil unless updated_sections.include?("default_attributes")

        h1("DEFAULT ATTRIBUTES CHANGED")

        old_default = pretty_json(old_lock["default_attributes"])
        new_default = pretty_json(new_lock["default_attributes"])
        diff_lines(old_default, new_default)
      end

      def report_override_attribute_changes
        return nil unless updated_sections.include?("override_attributes")

        h1("OVERRIDE ATTRIBUTES CHANGED")

        old_override = pretty_json(old_lock["override_attributes"])
        new_override = pretty_json(new_lock["override_attributes"])
        diff_lines(old_override, new_override)
      end

      def added_cookbooks
        detect_cookbook_changes if @added_cookbooks.nil?
        @added_cookbooks
      end

      def removed_cookbooks
        detect_cookbook_changes if @removed_cookbooks.nil?
        @removed_cookbooks
      end

      def modified_cookbooks
        detect_cookbook_changes if @modified_cookbooks.nil?
        @modified_cookbooks
      end

      private

      def h1(str)
        ui.msg(str)
        ui.msg("=" * str.size)
      end

      def h2(str)
        ui.msg(str)
        ui.msg("-" * str.size)
      end

      def diff_lines(old_lines, new_lines)
        file_length_difference = INITIAL_FILE_LENGTH_DIFFERENCE

        previous_hunk = nil

        diffs = Diff::LCS.diff(old_lines, new_lines)

        ui.print("\n")

        diffs.each do |piece|
          hunk = Diff::LCS::Hunk.new(old_lines, new_lines, piece, LINES_OF_CONTEXT, file_length_difference)

          file_length_difference = hunk.file_length_difference

          maybe_contiguous_hunks = (previous_hunk.nil? || hunk.merge(previous_hunk))

          if !maybe_contiguous_hunks
            print_color_diff("#{previous_hunk.diff(FORMAT)}\n")
          end
          previous_hunk = hunk
        end
        print_color_diff("#{previous_hunk.diff(FORMAT)}\n") unless previous_hunk.nil?
        ui.print("\n")
      end

      def print_color_diff(hunk)
        hunk.to_s.each_line do |line|
          ui.print(Paint[line, color_for_line(line)])
        end
      end

      def color_for_line(line)
        case line[0].chr
        when "+"
          :green
        when "-"
          :red
        when "@"
          line[1].chr == "@" ? :blue : nil
        else
          nil
        end
      end

      def pretty_json(data)
        FFI_Yajl::Encoder.encode(data, pretty: true).lines.map { |l| l.chomp }
      end

      def detect_cookbook_changes
        all_locked_cookbooks = old_cookbook_locks.keys | new_cookbook_locks.keys

        @added_cookbooks = []
        @removed_cookbooks = []
        @modified_cookbooks = []

        all_locked_cookbooks.each do |cb_name|
          if old_cookbook_locks.key?(cb_name) && new_cookbook_locks.key?(cb_name)
            old_cb_lock = old_cookbook_locks[cb_name]
            new_cb_lock = new_cookbook_locks[cb_name]
            if old_cb_lock != new_cb_lock
              @modified_cookbooks << cb_name
            end
          elsif old_cookbook_locks.key?(cb_name)
            @removed_cookbooks << cb_name
          elsif new_cookbook_locks.key?(cb_name)
            @added_cookbooks << cb_name
          else
            raise "Bug: cookbook lock #{cb_name} cannot be determined as new/removed/modified/unmodified"
          end
        end
      end

    end
  end
end
