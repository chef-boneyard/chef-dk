#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
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

module ChefDK
  module Policyfile

    # A policyfile lock fetcher that can read a lock from a local disk
    class LocalLockFetcher

      attr_reader :name
      attr_reader :source_options
      attr_reader :storage_config

      # Initialize a LocalLockFetcher
      #
      # @param name [String] The name of the policyfile
      # @param source_options [Hash] A hash with a :path key pointing at the location
      #                              of the lock
      # @param storage_config [StorageConfig]
      def initialize(name, source_options, storage_config)
        @name = name
        @source_options = source_options
        @storage_config = storage_config
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

        [:path].each do |key|
          error_messages << "include_policy for #{name} is missing key #{key}" unless source_options[key]
        end

        error_messages
      end

      # @return [Hash] The source_options that describe how to fetch this exact lock again
      def source_options_for_lock
        source_options
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
        FFI_Yajl::Parser.new.parse(content).tap do |data|
          data["cookbook_locks"].each do |cookbook_name, cookbook_lock|
            cookbook_path = cookbook_lock["source_options"]["path"]
            if !cookbook_path.nil?
              cookbook_lock["source_options"]["path"] = transform_path(cookbook_path)
            end
          end
        end
      end

      private

      # Transforms cookbook paths to a path relative to the current
      # cookbook for which we are generating a new lock file.
      # Eg: '../cookbooks/base_cookbook'
      #
      # @param path_to_transform [String] Path to dependent cookbook.
      # @return [Pathname] Path to dependent cookbook relative to the current cookbook/Policyfile.
      def transform_path(path_to_transform)
        cur_path = Pathname.new(storage_config.relative_paths_root)
        include_path = Pathname.new(path).dirname
        include_path.relative_path_from(cur_path).join(path_to_transform).to_s
      end

      def content
        IO.read(path)
      end

      def path
        @path ||= begin
          path = abs_path
          if path.directory?
            path = path.join("#{name}.lock.json")
            if !path.file?
              raise ChefDK::LocalPolicyfileLockNotFound.new(
                "Expected to find file #{name}.lock.json inside #{source_options[:path]}. If the file name is different than this, provide the file name as part of the path.")
            end
          else
            if !path.file?
              raise ChefDK::LocalPolicyfileLockNotFound.new(
                "The provided path #{source_options[:path]} does not exist.")
            end
          end
          path
        end
      end

      def abs_path
        Pathname.new(source_options[:path]).expand_path(storage_config.relative_paths_root)
      end
    end
  end
end
