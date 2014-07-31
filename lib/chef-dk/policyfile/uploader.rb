#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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

require 'chef/cookbook_uploader'
require 'chef-dk/policyfile/read_cookbook_for_compat_mode_upload'

module ChefDK
  module Policyfile
    class Uploader

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
          "id" => policy_id,
          "name" => "data_bag_item_#{COMPAT_MODE_DATA_BAG_NAME}_#{policy_id}",
          "data_bag" => COMPAT_MODE_DATA_BAG_NAME,
          "raw_data" => lock_data,
          # we'd prefer to leave this out, but the "compatibility mode"
          # implementation in chef-client relies on magical class inflation
          "json_class" => "Chef::DataBagItem"
        }

        upload_lockfile_as_data_bag_item(policy_id, data_item)
      end

      def uploader
        # TODO: uploader runs cookbook validation; we want to do this at a different time.
        @uploader ||= Chef::CookbookUploader.new(cookbook_versions_to_upload, :rest => http_client)
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
