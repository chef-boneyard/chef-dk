require 'chef-dk/policyfile_lock'

module ChefDK
  module Policyfile
    class PolicyfileLocationSpecification

      attr_reader :name
      attr_reader :source_options
      attr_reader :storage_config
      attr_reader :ui

      def initialize(name, source_options, storage_config)
        @name = name
        @source_options = source_options
        @storage_config = storage_config
        @ui = nil
      end

      def installed?
        true
      end

      def ensure_cached
      end

      def valid?
        errors.empty?
      end

      def errors
        error_messages = []
        error_messages
      end

      def policyfile_lock
        @policyfile_lock ||= begin
          ensure_cached
          PolicyfileLock.new(storage_config, ui: ui).build_from_lock_data(lock_data)
        end
      end

      private

      def lock_data
        FFI_Yajl::Parser.new.parse(content)
      end

      def content
        IO.read(path)
      end

      def path
        # TODO: Move to local fetcher implementation
        path = Pathname.new(source_options[:local])
        if !path.absolute?
          path = Pathname.new(storage_config.relative_paths_root).join(path)
        end
        path
      end
    end
  end
end

