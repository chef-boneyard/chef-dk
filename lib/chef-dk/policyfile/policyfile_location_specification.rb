require "chef-dk/policyfile_lock"
require "chef-dk/policyfile/local_lock_fetcher"
require "chef-dk/policyfile/chef_server_lock_fetcher"

module ChefDK
  module Policyfile
    class PolicyfileLocationSpecification

      attr_reader :name
      attr_reader :source_options
      attr_reader :storage_config
      attr_reader :chef_config
      attr_reader :ui

      LOCATION_TYPES = [:git, :local, :server]

      def initialize(name, source_options, storage_config, chef_config = nil)
        @name = name
        @source_options = source_options
        @storage_config = storage_config
        @ui = nil
        @chef_config = chef_config
      end

      def revision_id
        fetcher.lock_data["revision_id"]
      end

      def fetcher
        @fetcher ||= begin
                       if source_options[:server]
                         Policyfile::ChefServerLockFetcher.new(name, source_options, chef_config)
                       elsif source_options[:local]
                         Policyfile::LocalLockFetcher.new(name, source_options, chef_config)
                       else
                         raise "Invalid policyfile lock location type"
                       end
                     end
      end

      def valid?
        errors.empty?
      end

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

      def policyfile_lock
        @policyfile_lock ||= begin
                               PolicyfileLock.new(storage_config, ui: ui).build_from_lock_data(fetcher.lock_data)
                             end
      end

      def source_options_for_lock
        fetcher.source_options_for_lock
      end

      def apply_locked_source_options(options_from_lock)
        fetcher.apply_locked_source_options(options_from_lock)
      end
    end
  end
end
