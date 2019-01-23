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
    # @since 3.0
    #
    class GitLockFetcher
      attr_accessor :name
      attr_accessor :source_options
      attr_accessor :storage_config

      attr_reader :uri
      attr_reader :revision
      attr_reader :path
      attr_reader :branch
      attr_reader :tag
      attr_reader :ref

      # Initialize a GitLockFetcher
      #
      # @param name [String] The name of the policyfile
      # @param source_options [Hash] A hash with a :path key pointing at the location
      #                              of the lock
      def initialize(name, source_options, storage_config)
        @name           = name
        @storage_config = storage_config
        @source_options = symbolize_keys(source_options)
        @revision = @source_options[:revision]
        @path     = @source_options[:path] || @source_options[:rel]
        @uri      = @source_options[:git]
        @branch   = @source_options[:branch]
        @tag      = @source_options[:tag]
        @ref      = @source_options[:ref]

        # The revision to parse
        @rev_parse = @source_options[:ref] || @source_options[:branch] || @source_options[:tag] || "master"
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
                               revision: revision,
                             })
      end

      # Applies source options from a lock file. This is used to make sure that the same
      # policyfile lock is loaded that was locked
      #
      # @param options_from_lock [Hash] The source options loaded from a policyfile lock
      def apply_locked_source_options(options_from_lock)
        options = options_from_lock.inject({}) do |acc, (key, value)|
          acc[key.to_sym] = value
          acc
        end
        source_options.merge!(options)
        raise ChefDK::InvalidLockfile, "Invalid source_options provided from lock data: #{options_from_lock_file.inspect}" if !valid?
      end

      # @return [Hash] of the policyfile lock data
      def lock_data
        @lock_data ||= fetch_lock_data.tap do |data|
          data["cookbook_locks"].each do |cookbook_name, cookbook_lock|
            if cookbook_lock["source_options"].key?("path")
              cookbook_lock["source_options"].tap do |opt|
                opt["git"]      = uri unless opt.key?("git")
                opt["revision"] = revision unless opt.key?("revision")
                opt["branch"]   = branch unless opt.key?("branch") || branch.nil?
                opt["tag"]      = tag unless opt.key?("tag") || branch.nil?
                opt["ref"]      = ref unless opt.key?("ref") || ref.nil?

                path_keys = %w{path rel}.map { |path_key| path_key if opt.key?(path_key) }.compact

                path_keys.each do |name|
                  # We can safely grab the entire cookbook when the Policyfile defines a cookbook path of itself (".")
                  if opt[name] == "."
                    opt.delete(name)
                    next
                  end

                  # Mutate the path key to a rel key so that we identify the source_type
                  # as a git repo and not a local directory. Git also doesn't like paths
                  # prefixed with `./` and cannot use relative paths outside the repo.
                  # http://rubular.com/r/JYpdYHT19p
                  pattern = /(^..\/)|(^.\/)/
                  opt["rel"] = opt[name].gsub(pattern, "")
                end

                # Delete the path key if present to ensure we use the git source_type
                opt.delete("path")
              end
            end # cookbook_lock["source_options"]
          end # data["cookbook_locks"].each
        end # fetch_lock_data.tap

        @lock_data
      end

      private

      # Helper method to normalize data.
      #
      # @param [Hash] hash Hash with symbols and/or strings as keys.
      # @return [Hash] Hash with only symbols as keys.
      def symbolize_keys(hash)
        hash.inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo }
      end

      def fetch_lock_data
        install unless installed?
        FFI_Yajl::Parser.parse(
          show_file(rev_parse, lockfile_path)
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
          @revision ||= git %{rev-parse #{rev_parse}}
        end
      end

      def rev_parse
        source_options[:revision] || @rev_parse
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
