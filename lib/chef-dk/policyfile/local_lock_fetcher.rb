require "chef-dk/policyfile_lock"
require "chef-dk/exceptions"

module ChefDK
  module Policyfile
    class LocalLockFetcher

      attr_reader :name
      attr_reader :source_options
      attr_reader :storage_config

      def initialize(name, source_options, storage_config)
        @name = name
        @source_options = source_options
        @storage_config = storage_config
      end

      def valid?
        errors.empty?
      end

      def errors
        error_messages = []

        [:path].each do |key|
          error_messages << "include_policy for #{name} is missing key #{key}" unless source_options[key]
        end

        error_messages
      end

      def source_options_for_lock
        source_options
      end

      def apply_locked_source_options(options_from_lock)
        # There are no options the lock could provide
      end

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
          path = Pathname.new(source_options[:path])
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
          if !path.absolute?
            path = Pathname.new(storage_config.relative_paths_root).join(path)
          end
          path
        end
      end
    end
  end
end
