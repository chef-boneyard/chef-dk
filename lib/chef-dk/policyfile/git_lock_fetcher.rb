#
# Copyright:: Copyright (c) 2018 Chef Software Inc.
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

require "chef-dk/policyfile_lock"
require "chef-dk/exceptions"
require "chef-dk/helpers"
require "mixlib/shellout"
require "tmpdir"

module ChefDK
  module Policyfile

    # A Policyfile lock fetcher that can read a lock file from a git repository.
    #
    # @author Ryan Hass
    # @author Daniel DeLeo
    #
    # @since 3.1.0
    #
    class GitLockFetcher
      attr_accessor :name
      attr_accessor :source_options
      attr_accessor :storage_config

      attr_reader :uri
      attr_reader :branch
      attr_reader :tag
      attr_reader :ref
      attr_reader :revision
      attr_reader :path

      # Initialize a GitLockFetcher
      #
      # @param name [String] The name of the policyfile
      # @param source_options [Hash] A hash with a :path key pointing at the location
      #                              of the lock
      def initialize(name, source_options, storage_config)
        @name           = name
        @storage_config = storage_config
        @source_options = source_options

        @uri      = source_options[:git]
        @branch   = source_options[:branch]
        @tag      = source_options[:tag]
        @ref      = source_options[:ref]
        @revision = source_options[:revision]
        @path     = source_options[:path] || source_options[:rel]

        # The revision to parse
        @rev_parse = source_options[:ref] || source_options[:branch] || source_options[:tag] || "master"
      end

      # @return [True] if there were no errors with the provided source_options
      # @return [False] if there were errors with the provided source_options
      def valid?
        errors.empty?
      end

      # Check the options provided when craeting this class for errors
      #
      # @return [Array<String>] A list of errors found
      def errors
        error_messages = []
        [:git].each do |key|
          error_messages << "include_policy for #{name} is missing key #{key}" unless source_options[key]
        end

        error_messages
      end

      # @return [Hash] The source_options that describe how to fetch this exact lock again
      def source_options_for_lock
        source_options.merge({
                               revision:  revision,
                             })
      end

      # Applies source options from a lock file. This is used to make sure that the same
      # policyfile lock is loaded that was locked
      #
      # @param options_from_lock [Hash] The source options loaded from a policyfile lock
      def apply_locked_source_options(options_from_lock)
        # There are no options the lock could provide
      end

      # @return [String] of the policyfile lock data
      def lock_data
        @lock_data ||= fetch_lock_data.tap do |data|
          data["cookbook_locks"].each do |cookbook_name, cookbook_lock|
            cookbook_path = cookbook_lock["source_options"]["path"]
            cookbook_lock["source_options"].tap do |opt|
              if cookbook_lock.has_key?("scm_info")
                opt["rel"] = opt["path"] unless opt["path"] == "."
                opt.delete("path")
                opt["git"] = cookbook_lock["scm_info"]["remote"]
                # Note: In instances where the Policyfile.lock is being
                # consumed from a cookbook, the cookbook from which it will be
                # consumed will always be one git revision behind. This is due
                # to the fact that one must generate a lock file which will
                # contain the git ref from the working copy and then commit
                # the resulting lock file artifact which will in turn create a
                # new git ref. However, this may be the incorrect behavior for
                # some users whom wish to commit the lock file along with any
                # changes in the same commit, and will require a different way
                # of generating the locks.
                opt["revision"] = cookbook_lock["scm_info"]["revision"]
              end
            end
          end
        end

        @lock_data
      end

      private

      def fetch_lock_data
        install unless installed?
        FFI_Yajl::Parser.new.parse(
          show_file(@rev_parse, lockfile_path)
        )
      end

      # COPYPASTA from CookbookOmnifetch
      def installed?
        !!(revision && cache_path.exist?)
      end

      # COPYPASTA from CookbookOmnifetch::GitLocation and Berkshelf::GitLocation
      # then munged since we do not have Policyfile validation in scope.
      # Install into the chefdk cookbook store. This method leverages a cached
      # git copy.
      def install
        if cached?
          Dir.chdir(cache_path) do
            git %{fetch --force --tags #{uri} "refs/heads/*:refs/heads/*"}
          end
        else
          git %{clone #{uri} "#{cache_path}" --bare --no-hardlinks}
        end

        Dir.chdir(cache_path) do
          @revision ||= git %{rev-parse #{@rev_parse}}
        end
      end

      # Shows contents of a file from a shallow or full clone repository for a
      # given git version.
      #
      # This method was originally made before I slammed a bunch of copypasta
      # code in which is generally more tied to a specific git ref.
      #
      # @param version Git version as a tag, branch, or ref.
      # @param file Full path to file including filename in repository
      #
      # @return [String] Content of specified file for a given revision.
      def show_file(version, file)
        git("show #{version}:#{file}", cwd: cache_path)
      end

      # COPYPASTA from CookbookOmnifetch
      # Location an executable in the current user's $PATH
      #
      # @return [String, nil]
      #   the path to the executable, or +nil+ if not present
      def which(executable)
        if File.file?(executable) && File.executable?(executable)
          executable
        elsif ENV["PATH"]
          path = ENV["PATH"].split(File::PATH_SEPARATOR).find do |p|
            File.executable?(File.join(p, executable))
          end
          path && File.expand_path(executable, path)
        end
      end

      # COPYPASTA from CookbookOmnifetch::Git
      # Perform a git command.
      #
      # @param [String] command
      #   the command to run
      # @param [Boolean] error
      #   whether to raise error if the command fails
      #
      # @raise [String]
      #   the +$stdout+ from the command
      def git(command, options = {})
        error = options[:error] || true
        unless which("git") || which("git.exe") || which("git.bat")
          raise GitNotInstalled
        end

        response = Mixlib::ShellOut.new(%{git #{command}}, options)
        response.run_command

        if error && response.error?
          raise GitError.new "#{command} #{cache_path}: #{response.stderr}"
        end

        response.stdout.strip
      end

      # COPYPASTA from CookbookOmnifetch::Git (then munged by me)
      # The path where this git repository is cached.
      #
      # @return [Pathname]
      def cache_path
        Pathname.new(File.expand_path(File.join(ChefDK::Helpers.chefdk_home, "cache")))
          .join(".cache", "git", Digest::SHA1.hexdigest(uri))
      end

      # COPYPASTA from CookbookOmnifetch::Git
      # Determine if this git repo has already been downloaded.
      #
      # @return [Boolean]
      def cached?
        cache_path.exist?
      end

      def lockfile_path
        @path.nil? ? "Policyfile.lock.json" : @path
      end
    end
  end
end
