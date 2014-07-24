
require 'chef/cookbook_uploader'
# TODO: missing require in chef/cookbook_version
require 'chef/digester'
require 'chef/cookbook/cookbook_version_loader'

require 'chef-dk/authenticated_http'

# TODO: FIX MONKEY PATCHING
class Chef
  class Cookbook
    class CookbookVersionLoader

      # CookbookVersionLoader is hardcoded to use the directory path as the
      # name, but we have oddly named directories. This problem could also be
      # solved by making chef require that metadata specify the cookbook name
      # (which should be happening eventually).
      attr_accessor :cookbook_name

    end
  end
end

module ChefDK
  module Policyfile
    class ReadCookbookForCompatModeUpload

      # Convenience method to load a cookbook, set up name and version overrides
      # as necessary, and return a Chef::CookbookVersion object.
      def self.load(name, version_override, directory_path)
        new(name, version_override, directory_path).cookbook_version
      end

      attr_reader :cookbook_name
      attr_reader :directory_path
      attr_reader :version_override

      def initialize(cookbook_name, version_override, directory_path)
        raise "TODO: TEST ME" unless $hax_mode
        @cookbook_name = cookbook_name
        @version_override = version_override
        @directory_path = directory_path

        @cookbook_version = nil
        @loader = nil
      end

      def cookbook_version
        raise "TODO: TEST ME" unless $hax_mode
        @cookbook_version ||=
          begin
            cookbook_version = loader.cookbook_version
            cookbook_version.version = version_override
            cookbook_version.freeze_version
            cookbook_version
          end
      end

      # TODO: handle chefignore
      def chefignore
        raise "TODO: TEST ME" unless $hax_mode
        nil
      end

      def loader
        raise "TODO: TEST ME" unless $hax_mode
        @loader ||=
          begin
            cbvl = Chef::Cookbook::CookbookVersionLoader.new(directory_path, chefignore)
            cbvl.cookbook_name = cookbook_name
            cbvl.load_cookbooks
            cbvl
          end
      end

    end

    class Uploader

      # TODO: Fix API of CookbookUploader
      UNUSED_ARGUMENT = nil # :(

      COMPAT_MODE_DATA_BAG_NAME = "policyfiles".freeze

      attr_reader :policyfile_lock
      attr_reader :policy_group
      attr_reader :http_client

      def initialize(policyfile_lock, policy_group, http_client: nil)
        @policyfile_lock = policyfile_lock
        @policy_group = policy_group
        @http_client = http_client
      end

      def upload
        uploader.upload_cookbooks
        data_bag_create
        data_bag_item_create
      end

      def data_bag_create
        http_client.post("data", {"name" => COMPAT_MODE_DATA_BAG_NAME})
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "409"
      end

      def data_bag_item_create
        policy_id = "#{policyfile_lock.name}-#{policy_group}"
        lock_data = policyfile_lock.to_lock.dup

        lock_data["id"] = policy_id

        data_item = {
          "name" => policy_id,
          "data_bag" => COMPAT_MODE_DATA_BAG_NAME,
          "raw_data" => lock_data
        }

        upload_lockfile_as_data_bag_item(policy_id, data_item)
      end

      def uploader
        # TODO:
        # * uploader calls the _rest methods on http_client;
        # * uploader runs cookbook validation; we want to do this at a different time.
        # * fix uploader constructor.
        @uploader ||= Chef::CookbookUploader.new(cookbook_versions_to_upload, UNUSED_ARGUMENT, :rest => http_client)
      end

      def cookbook_versions_to_upload
        cookbook_versions_for_policy.reject do |cookbook|
          remote_already_has_cookbook?(cookbook)
        end
      end

      def remote_already_has_cookbook?(cookbook)
        return false unless existing_cookbook_on_remote.key?(cookbook.name.to_s)

        existing_cookbook_on_remote[cookbook.name.to_s]["versions"].any? do |cookbook_info|
          cookbook_info["version"] == cookbook.version
        end
      end

      def existing_cookbook_on_remote
        @existing_cookbook_on_remote ||= http_client.get('cookbooks?num_versions=all')
      end

      # An Array of Chef::CookbookVersion objects representing the full set that
      # the policyfile lock requires.
      def cookbook_versions_for_policy
        policyfile_lock.validate_cookbooks!
        policyfile_lock.cookbook_locks.map do |name, lock|
          ReadCookbookForCompatModeUpload.load(name, lock.dotted_decimal_identifier, lock.cookbook_path)
        end
      end

      private

      def upload_lockfile_as_data_bag_item(policy_id, data_item)
        http_client.put("data/#{COMPAT_MODE_DATA_BAG_NAME}/#{policy_id}", data_item)
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        http_client.post("data/#{COMPAT_MODE_DATA_BAG_NAME}", data_item)
      end
    end
  end
end
