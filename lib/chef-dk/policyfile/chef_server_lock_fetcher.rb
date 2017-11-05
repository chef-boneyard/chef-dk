require 'chef-dk/policyfile_lock'

module ChefDK
  module Policyfile
    class ChefServerLockFetcher

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

        [:server, :policy_name, :policy_revision_id].each do |key|
          error_messages << "include_policy for #{name} is missing key #{key}" unless source_options[key]
        end

        error_messages
      end

      def lock_data
        http_client.get("policies/#{policy_name}/revisions/#{revision}")
      rescue Net::ProtocolError => e
        if e.respond_to?(:response) && e.response.code.to_s == "404"
          raise PolicyfileDownloadError.new("No policyfile lock named '#{policy_name}' found with revision '#{revision}' at #{http_client.url}", e)
        else
          raise PolicyfileDownloadError.new("HTTP error attempting to fetch policyfile lock from #{http_client.url}", e)
        end
      rescue => e
        raise PolicyfileDownloadError.new("Failed to fetch policyfile lock from #{http_client.url}", e)
      end

      private

      def policy_name
        source_options[:policy_name]
      end

      def revision
        source_options[:policy_revision_id]
      end

      def http_client
        @http_client ||= Chef::ServerAPI.new(source_options[:server],
                                             signing_key_filename: chef_config.client_key,
                                             client_name: chef_config.node_name)
      end

    end
  end
end


