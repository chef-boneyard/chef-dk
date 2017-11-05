require 'chef-dk/policyfile_lock'

module ChefDK
  module Policyfile
    class LocalLockFetcher

      attr_accessor :name
      attr_accessor :source_options
      attr_accessor :chef_config
     
      def initialize(name, source_options, chef_config)
        @name = name
        @source_options = source_options
        @chef_config = chef_config
      end

      def valid?
        errors.empty?
      end

      def errors
        error_messages = []

        [:local].each do |key|
          error_messages << "include_policy for #{name} is missing key #{key}" unless source_options[key]
        end

        error_messages
      end

      def lock_data
        FFI_Yajl::Parser.new.parse(content)
      end

      private

      def content
        IO.read(path)
      end

      def path
        Pathname.new(source_options[:local])
      end

    end
  end
end


