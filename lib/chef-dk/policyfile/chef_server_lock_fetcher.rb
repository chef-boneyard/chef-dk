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

    # A policyfile lock fetcher that can read a lock from a chef server
    class ChefServerLockFetcher

      attr_accessor :name
      attr_accessor :source_options
      attr_accessor :chef_config

      # Initialize a LocalLockFetcher
      #
      # @param name [String] The name of the policyfile
      # @param source_options [Hash] A hash with a :server key pointing at the chef server,
      # along with :policy_name and either :policy_group or :policy_revision_id. If :policy_name
      # is not provided, name is used.
      # @param chef_config [Chef::Config, ChefConfig::Config]
      #
      # @example ChefServerLockFetcher for a policyfile with a specific revision id
      #   ChefServerLockFetcher.new("foo",
      #     {server: "http://example.com", policy_revision_id: "abcdabcdabcd"},
      #     chef_config)
      #
      #   ChefServerLockFetcher.new("foo",
      #     {server: "http://example.com", policy_name: "foo", policy_revision_id: "abcdabcdabcd"},
      #     chef_config)
      #
      # @example ChefServerLockFetcher for a policyfile with the latest revision_id for a policy group
      #   ChefServerLockFetcher.new("foo",
      #     {server: "http://example.com", policy_group: "dev"},
      #     chef_config)
      #
      #   ChefServerLockFetcher.new("foo",
      #     {server: "http://example.com", policy_name: "foo", policy_group: "dev"},
      #     chef_config)
      def initialize(name, source_options, chef_config)
        @name = name
        @source_options = source_options
        @chef_config = chef_config

        @source_options[:policy_name] ||= name
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

        [:server, :policy_name].each do |key|
          error_messages << "include_policy for #{name} is missing key #{key}" unless source_options[key]
        end

        if [:policy_revision_id, :policy_group].all? { |key| source_options[key].nil? }
          error_messages << "include_policy for #{name} must specify policy_revision_id or policy_group"
        end

        error_messages
      end

      # @return [Hash] The source_options that describe how to fetch this exact lock again
      def source_options_for_lock
        source_options.merge({
          policy_revision_id: lock_data["revision_id"],
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

      # @return [String] of the policyfile lock data
      def lock_data
        @lock_data ||= fetch_lock_data.tap do |data|
          data["cookbook_locks"].each do |cookbook_name, cookbook_lock|
            cookbook_lock["source_options"] = {
              "chef_server_artifact" => server,
              "identifier" => cookbook_lock["identifier"],
            }
          end
        end
      end

      private

      def fetch_lock_data
        if revision
          http_client.get("policies/#{policy_name}/revisions/#{revision}")
        elsif policy_group
          http_client.get("policy_groups/#{policy_group}/policies/#{policy_name}")
        else
          raise ChefDK::BUG.new("The source_options should have been validated: #{source_options.inspect}")
        end
      rescue Net::ProtocolError => e
        if e.respond_to?(:response) && e.response.code.to_s == "404"
          raise ChefDK::PolicyfileLockDownloadError.new("No policyfile lock named '#{policy_name}' found with revision '#{revision}' at #{http_client.url}") if revision
          raise ChefDK::PolicyfileLockDownloadError.new("No policyfile lock named '#{policy_name}' found with policy group '#{policy_group}' at #{http_client.url}") if policy_group
        else
          raise ChefDK::PolicyfileLockDownloadError.new("HTTP error attempting to fetch policyfile lock from #{http_client.url}")
        end
      rescue => e
        raise e
      end

      def policy_name
        source_options[:policy_name]
      end

      def revision
        source_options[:policy_revision_id]
      end

      def policy_group
        source_options[:policy_group]
      end

      def server
        source_options[:server]
      end

      # @see Chef:ServerAPI
      # @see Chef::HTTP::JSONInput#get
      # @return [Hash] Returns a parsed JSON object... I think.
      def http_client
        @http_client ||= Chef::ServerAPI.new(source_options[:server],
                                             signing_key_filename: chef_config.client_key,
                                             client_name: chef_config.node_name)
      end

    end
  end
end
