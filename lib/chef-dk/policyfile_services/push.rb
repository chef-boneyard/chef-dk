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

require "ffi_yajl"

require "chef-dk/service_exceptions"
require "chef/server_api"
require "chef-dk/policyfile_compiler"
require "chef-dk/policyfile/uploader"
require "chef-dk/policyfile/storage_config"

module ChefDK
  module PolicyfileServices
    class Push

      include Policyfile::StorageConfigDelegation
      include ChefDK::Helpers

      attr_reader :root_dir
      attr_reader :config
      attr_reader :policy_group
      attr_reader :ui
      attr_reader :storage_config

      def initialize(policyfile: nil, ui: nil, policy_group: nil, config: nil, root_dir: nil)
        @root_dir = root_dir
        @ui = ui
        @config = config
        @policy_group = policy_group

        policyfile_rel_path = policyfile || "Policyfile.rb"
        policyfile_full_path = File.expand_path(policyfile_rel_path, root_dir)
        @storage_config = Policyfile::StorageConfig.new.use_policyfile(policyfile_full_path)

        @http_client = nil
        @policy_data = nil
      end

      def http_client
        @http_client ||= Chef::ServerAPI.new(config.chef_server_url,
                                                       signing_key_filename: config.client_key,
                                                       client_name: config.node_name)
      end

      def policy_data
        @policy_data ||= FFI_Yajl::Parser.parse(IO.read(policyfile_lock_expanded_path))
      rescue => error
        raise PolicyfilePushError.new("Error reading lockfile #{policyfile_lock_expanded_path}", error)
      end

      def uploader
        ChefDK::Policyfile::Uploader.new(policyfile_lock, policy_group,
                                         ui: ui,
                                         http_client: http_client,
                                         policy_document_native_api: config.policy_document_native_api)
      end

      def run
        unless File.exist?(policyfile_lock_expanded_path)
          raise LockfileNotFound, "No lockfile at #{policyfile_lock_expanded_path} - you need to run `install` before `push`"
        end

        validate_lockfile
        write_updated_lockfile
        upload_policy
      end

      def policyfile_lock
        @policyfile_lock || validate_lockfile
      end

      private

      def upload_policy
        uploader.upload
      rescue => error
        raise PolicyfilePushError.new("Failed to upload policy to policy group #{policy_group}", error)
      end

      def write_updated_lockfile
        with_file(policyfile_lock_expanded_path) do |f|
          f.print(FFI_Yajl::Encoder.encode(policyfile_lock.to_lock, pretty: true ))
        end
      end

      def validate_lockfile
        return @policyfile_lock if @policyfile_lock
        @policyfile_lock = ChefDK::PolicyfileLock.new(storage_config).build_from_lock_data(policy_data)
        # TODO: enumerate any cookbook that have been updated
        @policyfile_lock.validate_cookbooks!
        @policyfile_lock
      rescue => error
        raise PolicyfilePushError.new("Invalid lockfile data", error)
      end

    end
  end
end
