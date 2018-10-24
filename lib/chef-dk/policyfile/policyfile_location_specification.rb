#
# Copyright:: Copyright (c) 2017-2018 Chef Software Inc.
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
require "chef-dk/policyfile/local_lock_fetcher"
require "chef-dk/policyfile/chef_server_lock_fetcher"
require "chef-dk/policyfile/git_lock_fetcher"
require "chef-dk/exceptions"

module ChefDK
  module Policyfile
    # A PolicyfileLocationSpecification specifies where a policyfile lock is to be fetched from.
    # Using this information, it provides a fetcher that is capable loading the policyfile
    # lock.
    #
    # @attr_reader [String] name The name of the policyfile
    # @attr_reader [Hash] source_options Options describing how to get the policyfile lock
    class PolicyfileLocationSpecification
      attr_reader :name
      attr_reader :source_options

      attr_reader :storage_config
      attr_reader :chef_config
      attr_reader :ui

      LOCATION_TYPES = [:path, :server, :git].freeze

      # Initialize a location spec
      #
      # @param name [String] the name of the policyfile
      # @param source_options [Hash] options describing where the policyfile lock lives
      # @param storage_config [Policyfile::StorageConfig]
      # @param chef_config [Chef::Config] chef config that will be used when communication
      #                    with a chef server is required
      def initialize(name, source_options, storage_config, chef_config = nil)
        @name = name
        @source_options = source_options
        @storage_config = storage_config
        @ui = nil
        @chef_config = chef_config
      end

      # @return The revision id from the fetched lock
      def revision_id
        fetcher.lock_data["revision_id"]
      end

      # @return A policyfile lock fetcher compatible with the given source_options
      def fetcher
        @fetcher ||= begin
                       if source_options[:path] && !source_options[:git]
                         Policyfile::LocalLockFetcher.new(name, source_options, storage_config)
                       elsif source_options[:server]
                         Policyfile::ChefServerLockFetcher.new(name, source_options, chef_config)
                       elsif source_options[:git]
                         Policyfile::GitLockFetcher.new(name, source_options, storage_config)
                       else
                         raise ChefDK::InvalidPolicyfileLocation.new(
                           "Invalid policyfile lock location type. The supported locations are: #{LOCATION_TYPES.join(", ")}"
                         )
                       end
                     end
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

        if LOCATION_TYPES.all? { |l| source_options[l].nil? }
          error_messages << "include_policy must use one of the following sources: #{LOCATION_TYPES.join(', ')}"
        else
          if !fetcher.nil?
            error_messages += fetcher.errors
          end
        end

        error_messages
      end

      # Fetches and loads the policyfile lock
      #
      # @return [PolicyfileLock] the loaded policyfile lock
      def policyfile_lock
        @policyfile_lock ||= begin
                               PolicyfileLock.new(storage_config, ui: ui).build_from_lock_data(fetcher.lock_data)
                             end
      end

      # @return [Hash] The source_options that describe how to fetch this exact lock again
      def source_options_for_lock
        fetcher.source_options_for_lock
      end

      # Applies source options from a lock file. This is used to make sure that the same
      # policyfile lock is loaded that was locked
      #
      # @param options_from_lock [Hash] The source options loaded from a policyfile lock
      def apply_locked_source_options(options_from_lock)
        fetcher.apply_locked_source_options(options_from_lock)
      end
    end
  end
end
