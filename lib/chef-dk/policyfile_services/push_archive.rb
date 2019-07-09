#
# Copyright:: Copyright (c) 2015-2019 Chef Software Inc.
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

require "zlib"
require "archive/tar/minitar"

require_relative "../service_exceptions"
require_relative "../policyfile_lock"
require "chef/server_api"
require_relative "../policyfile/uploader"
require_relative "../dist"

module ChefDK
  module PolicyfileServices
    class PushArchive

      USTAR_INDICATOR = "ustar\0".force_encoding(Encoding::ASCII_8BIT).freeze

      attr_reader :archive_file
      attr_reader :policy_group
      attr_reader :root_dir
      attr_reader :ui
      attr_reader :config

      attr_reader :policyfile_lock

      def initialize(archive_file: nil, policy_group: nil, root_dir: nil, ui: nil, config: nil)
        @archive_file = archive_file
        @policy_group = policy_group
        @root_dir = root_dir || Dir.pwd
        @ui = ui
        @config = config

        @policyfile_lock = nil
      end

      def archive_file_path
        File.expand_path(archive_file, root_dir)
      end

      def run
        unless File.exist?(archive_file_path)
          raise InvalidPolicyArchive, "Archive file #{archive_file_path} not found"
        end

        stage_unpacked_archive do |staging_dir|
          read_policyfile_lock(staging_dir)

          uploader.upload
        end

      rescue => e
        raise PolicyfilePushArchiveError.new("Failed to publish archived policy", e)
      end

      # @api private
      def uploader
        ChefDK::Policyfile::Uploader.new(policyfile_lock, policy_group,
          ui: ui,
          http_client: http_client,
          policy_document_native_api: config.policy_document_native_api)
      end

      # @api private
      def http_client
        @http_client ||= Chef::ServerAPI.new(config.chef_server_url,
          signing_key_filename: config.client_key,
          client_name: config.node_name)
      end

      private

      def read_policyfile_lock(staging_dir)
        policyfile_lock_path = File.join(staging_dir, "Policyfile.lock.json")

        if looks_like_old_format_archive?(staging_dir)
          raise InvalidPolicyArchive, <<~MESSAGE
            This archive is in an unsupported format.

            This archive was created with an older version of #{ChefDK::Dist::PRODUCT}. This version of
            #{ChefDK::Dist::PRODUCT} does not support archives in the older format. Please Re-create the
            archive with a newer version of #{ChefDK::Dist::PRODUCT}.
          MESSAGE
        end

        unless File.exist?(policyfile_lock_path)
          raise InvalidPolicyArchive, "Archive does not contain a Policyfile.lock.json"
        end

        unless File.directory?(File.join(staging_dir, "cookbook_artifacts"))
          raise InvalidPolicyArchive, "Archive does not contain a cookbook_artifacts directory"
        end

        policy_data = load_policy_data(policyfile_lock_path)
        storage_config = Policyfile::StorageConfig.new.use_policyfile_lock(policyfile_lock_path)
        @policyfile_lock = ChefDK::PolicyfileLock.new(storage_config).build_from_archive(policy_data)

        missing_cookbooks = policyfile_lock.cookbook_locks.select do |name, lock|
          !lock.installed?
        end

        unless missing_cookbooks.empty?
          message = "Archive does not have all cookbooks required by the Policyfile.lock. " +
            "Missing cookbooks: '#{missing_cookbooks.keys.join('", "')}'."
          raise InvalidPolicyArchive, message
        end
      end

      def load_policy_data(policyfile_lock_path)
        FFI_Yajl::Parser.parse(IO.read(policyfile_lock_path))
      end

      def stage_unpacked_archive
        p = Process.pid
        t = Time.new.utc.strftime("%Y%m%d%H%M%S")
        Dir.mktmpdir("chefdk-push-archive-#{p}-#{t}") do |staging_dir|
          unpack_to(staging_dir)
          yield staging_dir
        end
      end

      def unpack_to(staging_dir)
        Mixlib::Archive.new(archive_file_path).extract(staging_dir)
      rescue => e
        raise InvalidPolicyArchive, "Archive file #{archive_file_path} could not be unpacked. #{e}"
      end

      def looks_like_old_format_archive?(staging_dir)
        cookbooks_dir = File.join(staging_dir, "cookbooks")
        data_bags_dir = File.join(staging_dir, "data_bags")

        cookbook_artifacts_dir = File.join(staging_dir, "cookbook_artifacts")
        policies_dir = File.join(staging_dir, "policies")
        policy_groups_dir = File.join(staging_dir, "policy_groups")

        # Old archives just had these two dirs
        have_old_dirs = File.exist?(cookbooks_dir) && File.exist?(data_bags_dir)

        # New archives created by `chef export` will have all of these; it's
        # also possible we'll encounter an "artisanal" archive, which might
        # only be missing one of these by accident. In that case we want to
        # trigger a different error than we're detecting here.
        have_any_new_dirs = File.exist?(cookbook_artifacts_dir) ||
          File.exist?(policies_dir) ||
          File.exist?(policy_groups_dir)

        have_old_dirs && !have_any_new_dirs
      end

    end
  end
end
