#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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

require "chef-dk/helpers"

module ChefDK
  module CookbookProfiler
    class Git

      include Helpers

      attr_reader :cookbook_path

      def initialize(cookbook_path)
        @cookbook_path = cookbook_path
        @unborn_branch = nil
        @unborn_branch_ref = nil
      end

      # @return [Hash] Hashed used for pinning cookbook versions within a Policfile.lock
      def profile_data
        {
          "scm" => "git",
          # To get this info, you need to do something like:
          # figure out branch or assume 'master'
          # git config --get branch.master.remote
          # git config --get remote.opscode.url
          "remote" => remote,
          "revision" => revision,
          "working_tree_clean" => clean?,
          "published" => !unpublished_commits?,
          "synchronized_remote_branches" => synchronized_remotes,
        }
      end

      def revision
        git!("rev-parse HEAD").stdout.strip
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        # We may have an "unborn" branch, i.e. one with no commits.
        if unborn_branch_ref
          nil
        else
          # if we got here, but verify_ref_cmd didn't error, we don't know why
          # the original git command failed, so re-raise.
          raise e
        end
      end

      def clean?
        git!("diff-files --quiet", returns: [0, 1]).exitstatus == 0
      end

      def unpublished_commits?
        synchronized_remotes.empty?
      end

      def synchronized_remotes
        @synchronized_remotes ||= git!("branch -r --contains #{revision}").stdout.lines.map(&:strip)
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        # We may have an "unborn" branch, i.e. one with no commits.
        if unborn_branch_ref
          []
        else
          # if we got here, but verify_ref_cmd didn't error, we don't know why
          # the original git command failed, so re-raise.
          raise e
        end
      end

      def remote
        @remote_url ||=
          if have_remote?
            git!("config --get remote.#{remote_name}.url").stdout.strip
          else
            nil
          end
      end

      def remote_name
        @remote_name ||= git!("config --get branch.#{current_branch}.remote", returns: [0, 1]).stdout.strip
      end

      def have_remote?
        !remote_name.empty? && remote_name != "."
      end

      def current_branch
        @current_branch ||= detect_current_branch
      end

      private

      def git!(subcommand, options = {})
        cmd = git(subcommand, options)
        cmd.error!
        cmd
      end

      def git(subcommand, options = {})
        options = { cwd: cookbook_path }.merge(options)
        system_command("git #{subcommand}", options)
      end

      def detect_current_branch
        branch = git!("rev-parse --abbrev-ref HEAD").stdout.strip
        @unborn_branch = false
        branch
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        # We may have an "unborn" branch, i.e. one with no commits.
        if unborn_branch_ref
          unborn_branch_ref
        else
          # if we got here, but verify_ref_cmd didn't error, we don't know why
          # the original git command failed, so re-raise.
          raise e
        end
      end

      def unborn_branch_ref
        @unborn_branch_ref ||=
          begin
            strict_branch_ref = git!("symbolic-ref -q HEAD").stdout.strip
            verify_ref_cmd = git("show-ref --verify #{strict_branch_ref}")
            if verify_ref_cmd.error?
              @unborn_branch = true
              strict_branch_ref
            else
              # if we got here, but verify_ref_cmd didn't error, then `git
              # rev-parse` is probably failing for a reason we haven't anticipated.
              # Calling code should detect this and re-raise.
              nil
            end
          end
      end

    end
  end
end
