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

require 'fileutils'

require 'chef-dk/service_exceptions'
require 'chef-dk/policyfile_lock'
require 'chef-dk/policyfile/storage_config'

module ChefDK
  module PolicyfileServices

    class ExportRepo

      # Policy groups provide namespaces for policies so that a Chef Server can
      # have multiple active iterations of a policy at once, but we don't need
      # this when serving a single exported policy via Chef Zero, so hardcode
      # it to a "well known" value:
      POLICY_GROUP = 'local'.freeze

      include Policyfile::StorageConfigDelegation

      attr_reader :storage_config
      attr_reader :root_dir
      attr_reader :export_dir

      def initialize(policyfile: nil, export_dir: nil, root_dir: nil, force: false)
        @root_dir = root_dir
        @export_dir = File.expand_path(export_dir)
        @force_export = force

        @policy_data = nil
        @policyfile_lock = nil

        policyfile_rel_path = policyfile || "Policyfile.rb"
        policyfile_full_path = File.expand_path(policyfile_rel_path, root_dir)
        @storage_config = Policyfile::StorageConfig.new.use_policyfile(policyfile_full_path)
      end

      def run
        assert_lockfile_exists!
        assert_export_dir_empty!

        validate_lockfile
        write_updated_lockfile
        export
      end

      def policy_data
        @policy_data ||= FFI_Yajl::Parser.parse(IO.read(policyfile_lock_expanded_path))
      rescue => error
        raise PolicyfileExportRepoError.new("Error reading lockfile #{policyfile_lock_expanded_path}", error)
      end

      def policyfile_lock
        @policyfile_lock || validate_lockfile
      end

      def export
        create_repo_structure
        copy_cookbooks
        create_policyfile_data_item
      rescue => error
        msg = "Failed to export policy (in #{policyfile_filename}) to #{export_dir}"
        raise PolicyfileExportRepoError.new(msg, error)
      end

      private

      def create_repo_structure
        FileUtils.rm_rf(export_dir)
        FileUtils.mkdir_p(export_dir)
        FileUtils.mkdir_p(File.join(export_dir, "cookbooks"))
        FileUtils.mkdir_p(File.join(export_dir, "data_bags", "policyfiles"))
      end

      def copy_cookbooks
        policyfile_lock.cookbook_locks.each do |name, lock|
          copy_cookbook(lock)
        end
      end

      def copy_cookbook(lock)
        dirname = "#{lock.name}-#{lock.dotted_decimal_identifier}"
        export_path = File.join(export_dir, "cookbooks", dirname)
        metadata_rb_path = File.join(export_path, "metadata.rb")
        FileUtils.cp_r(lock.cookbook_path, export_path)
        FileUtils.rm_f(metadata_rb_path)
        metadata = lock.cookbook_version.metadata
        metadata.version(lock.dotted_decimal_identifier)

        metadata_json_path = File.join(export_path, "metadata.json")

        File.open(metadata_json_path, "wb+") do |f|
          f.print(FFI_Yajl::Encoder.encode(metadata.to_hash, pretty: true ))
        end
      end

      def create_policyfile_data_item
        # TODO: duplicates c/policyfile/uploader, move logic to PolicyfileLock

        policy_id = "#{policyfile_lock.name}-#{POLICY_GROUP}"
        item_path = File.join(export_dir, "data_bags", "policyfiles", "#{policy_id}.json")

        lock_data = policyfile_lock.to_lock.dup

        lock_data["id"] = policy_id

        data_item = {
          "id" => policy_id,
          "name" => "data_bag_item_policyfiles_#{policy_id}",
          "data_bag" => "policyfiles",
          "raw_data" => lock_data,
          # we'd prefer to leave this out, but the "compatibility mode"
          # implementation in chef-client relies on magical class inflation
          "json_class" => "Chef::DataBagItem"
        }

        File.open(item_path, "wb+") do |f|
          f.print(FFI_Yajl::Encoder.encode(data_item, pretty: true ))
        end
      end

      def validate_lockfile
        return @policyfile_lock if @policyfile_lock
        @policyfile_lock = ChefDK::PolicyfileLock.new(storage_config).build_from_lock_data(policy_data)
        # TODO: enumerate any cookbook that have been updated
        @policyfile_lock.validate_cookbooks!
        @policyfile_lock
      rescue PolicyfileExportRepoError
        raise
      rescue => error
        raise PolicyfileExportRepoError.new("Invalid lockfile data", error)
      end

      def write_updated_lockfile
        File.open(policyfile_lock_expanded_path, "wb+") do |f|
          f.print(FFI_Yajl::Encoder.encode(policyfile_lock.to_lock, pretty: true ))
        end
      end

      def assert_lockfile_exists!
        unless File.exist?(policyfile_lock_expanded_path)
          raise LockfileNotFound, "No lockfile at #{policyfile_lock_expanded_path} - you need to run `install` before `push`"
        end
      end

      def assert_export_dir_empty!
        entries = Dir.glob(File.join(export_dir, "*"))
        if !force_export? && !entries.empty?
          raise ExportDirNotEmpty, "Export dir (#{export_dir}) not empty. Refusing to export."
        end
      end

      def force_export?
        @force_export
      end

    end

  end
end

