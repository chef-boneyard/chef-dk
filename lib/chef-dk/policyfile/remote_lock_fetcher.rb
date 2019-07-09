#
# Copyright:: Copyright (c) 2019 Chef Software Inc.
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

require_relative "../policyfile_lock"
require_relative "lock_fetcher_mixin"
require_relative "../exceptions"
require "chef/http"
require "tempfile" unless defined?(Tempfile)

module ChefDK
  module Policyfile

    # A policyfile lock fetcher that can read a lock from a remote location.
    class RemoteLockFetcher
      include LockFetcherMixin

      attr_reader :name
      attr_reader :source_options

      # Initialize a RemoteLockFetcher
      #
      # @param name [String] The name of the policyfile
      # @param source_options [Hash] A hash with a :path key pointing at the location
      #                              of the lock
      def initialize(name, source_options)
        @name = name
        @source_options = source_options
      end

      # @return [True] if there were no errors with the provided source_options
      # @return [False] if there were errors with the provided source_options
      def valid?
        errors.empty?
      end

      # Check the options provided when creating this class for errors
      #
      # @return [Array<String>] A list of errors found
      def errors
        error_messages = []

        [:remote].each do |key|
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
        fetch_lock_data.tap do |data|
          validate_revision_id(data["revision_id"], source_options)
          data["cookbook_locks"].each do |cookbook_name, cookbook_lock|
            cookbook_path = cookbook_lock["source_options"]["path"]
            unless cookbook_path.nil?
              raise ChefDK::InvalidLockfile, "Invalid cookbook path: #{cookbook_path}. Remote Policyfiles should only use remote cookbooks."
            end
          end
        end
      end

      private

      def fetch_lock_data
        FFI_Yajl::Parser.parse(http_client.get(""))
      rescue Net::ProtocolError => e
        if e.respond_to?(:response) && e.response.code.to_s == "404"
          raise ChefDK::PolicyfileLockDownloadError.new("No remote policyfile lock '#{name}' found at #{http_client.url}")
        else
          raise ChefDK::PolicyfileLockDownloadError.new("HTTP error attempting to fetch policyfile lock from #{http_client.url}")
        end
      rescue => e
        raise e
      end

      def http_client
        @http_client ||= Chef::HTTP.new(source_options[:remote])
      end
    end
  end
end
