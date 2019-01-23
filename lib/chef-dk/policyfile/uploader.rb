#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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

require "chef/cookbook_uploader"
require "chef-dk/policyfile/read_cookbook_for_compat_mode_upload"

require "chef-dk/ui"
require "chef-dk/policyfile/reports/upload"

module ChefDK
  module Policyfile
    class Uploader

      LockedCookbookForUpload = Struct.new(:cookbook, :lock)

      COMPAT_MODE_DATA_BAG_NAME = "policyfiles".freeze

      attr_reader :policyfile_lock
      attr_reader :policy_group
      attr_reader :http_client
      attr_reader :ui

      def initialize(policyfile_lock, policy_group, ui: nil, http_client: nil, policy_document_native_api: false)
        @policyfile_lock = policyfile_lock
        @policy_group = policy_group
        @http_client = http_client
        @ui = ui || UI.null
        @policy_document_native_api = policy_document_native_api

        @policy_lock_for_transport = nil
        @cookbook_versions_for_policy = nil
      end

      def policy_name
        policyfile_lock.name
      end

      def upload
        ui.msg("Uploading policy #{policy_name} (#{short_revision_id}) to policy group #{policy_group}")

        if !using_policy_document_native_api?
          ui.msg(<<~DRAGONS)
            WARN: Uploading policy to policy group #{policy_group} in compatibility mode.
            Cookbooks will be uploaded with very large version numbers, which may be picked
            up by existing nodes.
          DRAGONS
        end

        upload_cookbooks
        upload_policy
      end

      def upload_policy
        if using_policy_document_native_api?
          upload_policy_native
        else
          data_bag_create
          data_bag_item_create
        end
      end

      def upload_policy_native
        http_client.put("/policy_groups/#{policy_group}/policies/#{policy_name}", policy_lock_for_transport)
      end

      def data_bag_create
        http_client.post("data", { "name" => COMPAT_MODE_DATA_BAG_NAME })
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "409"
      end

      def data_bag_item_create
        policy_id = "#{policy_name}-#{policy_group}"
        lock_data = policy_lock_for_transport.dup

        lock_data["id"] = policy_id

        data_item = {
          "id" => policy_id,
          "name" => "data_bag_item_#{COMPAT_MODE_DATA_BAG_NAME}_#{policy_id}",
          "data_bag" => COMPAT_MODE_DATA_BAG_NAME,
          "raw_data" => lock_data,
          # we'd prefer to leave this out, but the "compatibility mode"
          # implementation in chef-client relies on magical class inflation
          "json_class" => "Chef::DataBagItem",
        }

        upload_lockfile_as_data_bag_item(policy_id, data_item)
        ui.msg("Policy uploaded as data bag item #{COMPAT_MODE_DATA_BAG_NAME}/#{policy_id}")
        true
      end

      def uploader
        # TODO: uploader runs cookbook validation; we want to do this at a different time.
        @uploader ||= Chef::CookbookUploader.new(cookbook_versions_to_upload, rest: http_client, policy_mode: using_policy_document_native_api?)
      end

      def cookbook_versions_to_upload
        cookbook_versions_for_policy.inject([]) do |versions_to_upload, cookbook_with_lock|
          cb = cookbook_with_lock.cookbook
          # When we abandon custom identifier support in favor of the one true
          # hash, identifier generation code can be moved into chef proper and
          # this can be removed.
          cb.identifier = cookbook_with_lock.lock.identifier

          versions_to_upload << cb unless remote_already_has_cookbook?(cb)
          versions_to_upload
        end
      end

      def remote_already_has_cookbook?(cookbook)
        return false unless existing_cookbook_on_remote.key?(cookbook.name.to_s)

        if using_policy_document_native_api?
          native_mode_cookbook_exists_on_remote?(cookbook)
        else
          compat_mode_cookbook_exists_on_remote?(cookbook)
        end
      end

      def native_mode_cookbook_exists_on_remote?(cookbook)
        existing_cookbook_on_remote[cookbook.name.to_s]["versions"].any? do |cookbook_info|
          cookbook_info["identifier"] == cookbook.identifier
        end
      end

      def compat_mode_cookbook_exists_on_remote?(cookbook)
        existing_cookbook_on_remote[cookbook.name.to_s]["versions"].any? do |cookbook_info|
          cookbook_info["version"] == cookbook.version
        end
      end

      def existing_cookbook_on_remote
        @existing_cookbook_on_remote ||= http_client.get(list_cookbooks_url)
      end

      # An Array of Chef::CookbookVersion objects representing the full set that
      # the policyfile lock requires.
      def cookbook_versions_for_policy
        return @cookbook_versions_for_policy if @cookbook_versions_for_policy
        policyfile_lock.validate_cookbooks!
        @cookbook_versions_for_policy =
          if using_policy_document_native_api?
            load_cookbooks_in_native_mode
          else
            load_cookbooks_in_compat_mode
          end
      end

      def load_cookbooks_in_native_mode
        policyfile_lock.cookbook_locks.map do |name, lock|
          cb = CookbookLoaderWithChefignore.load(name, lock.cookbook_path)
          LockedCookbookForUpload.new(cb, lock)
        end
      end

      def load_cookbooks_in_compat_mode
        policyfile_lock.cookbook_locks.map do |name, lock|
          cb = ReadCookbookForCompatModeUpload.load(name, lock.dotted_decimal_identifier, lock.cookbook_path)
          LockedCookbookForUpload.new(cb, lock)
        end
      end

      def using_policy_document_native_api?
        @policy_document_native_api
      end

      private

      def short_revision_id
        policy_lock_for_transport["revision_id"][0, 10]
      end

      def policy_lock_for_transport
        @policy_lock_for_transport ||= policyfile_lock.to_lock
      end

      def list_cookbooks_url
        if using_policy_document_native_api?
          "cookbook_artifacts?num_versions=all"
        else
          "cookbooks?num_versions=all"
        end
      end

      def upload_cookbooks
        ui.msg("WARN: Uploading cookbooks using semver compat mode") unless using_policy_document_native_api?

        uploader.upload_cookbooks unless cookbook_versions_to_upload.empty?

        reused_cbs, uploaded_cbs = cookbook_versions_for_policy.partition do |cb_with_lock|
          remote_already_has_cookbook?(cb_with_lock.cookbook)
        end

        Reports::Upload.new(reused_cbs: reused_cbs, uploaded_cbs: uploaded_cbs, ui: ui).show

        true
      end

      def upload_lockfile_as_data_bag_item(policy_id, data_item)
        http_client.put("data/#{COMPAT_MODE_DATA_BAG_NAME}/#{policy_id}", data_item)
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        http_client.post("data/#{COMPAT_MODE_DATA_BAG_NAME}", data_item)
      end
    end
  end
end
