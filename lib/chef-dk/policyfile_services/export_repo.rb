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

require "pathname"
require "fileutils"
require "tmpdir"
require "zlib"

require "archive/tar/minitar"

require "chef/cookbook/chefignore"

require "chef-dk/service_exceptions"
require "chef-dk/policyfile_lock"
require "chef-dk/policyfile/storage_config"

module ChefDK
  module PolicyfileServices

    class ExportRepo

      # Policy groups provide namespaces for policies so that a Chef Server can
      # have multiple active iterations of a policy at once, but we don't need
      # this when serving a single exported policy via Chef Zero, so hardcode
      # it to a "well known" value:
      POLICY_GROUP = "local".freeze

      include Policyfile::StorageConfigDelegation

      attr_reader :storage_config
      attr_reader :root_dir
      attr_reader :export_dir

      def initialize(policyfile: nil, export_dir: nil, root_dir: nil, archive: false, force: false)
        @root_dir = root_dir
        @export_dir = File.expand_path(export_dir)
        @archive = archive
        @force_export = force

        @policy_data = nil
        @policyfile_lock = nil

        policyfile_rel_path = policyfile || "Policyfile.rb"
        policyfile_full_path = File.expand_path(policyfile_rel_path, root_dir)
        @storage_config = Policyfile::StorageConfig.new.use_policyfile(policyfile_full_path)

        @staging_dir = nil
      end

      def archive?
        @archive
      end

      def policy_name
        policyfile_lock.name
      end

      def run
        assert_lockfile_exists!
        assert_export_dir_clean!

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

      def archive_file_location
        return nil unless archive?
        filename = "#{policyfile_lock.name}-#{policyfile_lock.revision_id}.tgz"
        File.join(export_dir, filename)
      end

      def export
        with_staging_dir do
          create_repo_structure
          copy_cookbooks
          create_policyfile_repo_item
          create_policy_group_repo_item
          copy_policyfile_lock
          create_client_rb
          create_readme_md
          if archive?
            create_archive
          else
            mv_staged_repo
          end
        end
      rescue => error
        msg = "Failed to export policy (in #{policyfile_filename}) to #{export_dir}"
        raise PolicyfileExportRepoError.new(msg, error)
      end

      private

      def with_staging_dir
        p = Process.pid
        t = Time.new.utc.strftime("%Y%m%d%H%M%S")
        Dir.mktmpdir("chefdk-export-#{p}-#{t}") do |d|
          begin
            @staging_dir = d
            yield
          ensure
            @staging_dir = nil
          end
        end
      end

      def create_archive
        Dir.chdir(staging_dir) do
          targets = Find.find(".").collect { |e| e }
          Mixlib::Archive.new(archive_file_location).create(targets, gzip: true)
        end
      end

      def staging_dir
        @staging_dir
      end

      def create_repo_structure
        FileUtils.mkdir_p(export_dir)
        FileUtils.mkdir_p(dot_chef_staging_dir)
        FileUtils.mkdir_p(cookbook_artifacts_staging_dir)
        FileUtils.mkdir_p(policies_staging_dir)
        FileUtils.mkdir_p(policy_groups_staging_dir)
      end

      def copy_cookbooks
        policyfile_lock.cookbook_locks.each do |name, lock|
          copy_cookbook(lock)
        end
      end

      def copy_cookbook(lock)
        dirname = "#{lock.name}-#{lock.identifier}"
        export_path = File.join(staging_dir, "cookbook_artifacts", dirname)
        metadata_rb_path = File.join(export_path, "metadata.rb")
        FileUtils.mkdir(export_path) if not File.directory?(export_path)
        copy_unignored_cookbook_files(lock, export_path)
        FileUtils.rm_f(metadata_rb_path)
        metadata = lock.cookbook_version.metadata

        metadata_json_path = File.join(export_path, "metadata.json")

        File.open(metadata_json_path, "wb+") do |f|
          f.print(FFI_Yajl::Encoder.encode(metadata.to_hash, pretty: true ))
        end
      end

      def copy_unignored_cookbook_files(lock, export_path)
        cookbook_files_to_copy(lock.cookbook_path).each do |rel_path|
          full_source_path = File.join(lock.cookbook_path, rel_path)
          full_dest_path = File.join(export_path, rel_path)
          dest_dirname = File.dirname(full_dest_path)
          FileUtils.mkdir_p(dest_dirname) unless File.directory?(dest_dirname)
          FileUtils.cp(full_source_path, full_dest_path)
        end
      end

      def cookbook_files_to_copy(cookbook_path)
        cookbook = cookbook_loader_for(cookbook_path).cookbook_version

        root = Pathname.new(cookbook.root_dir)

        cookbook.all_files.map do |full_path|
          Pathname.new(full_path).relative_path_from(root).to_s
        end
      end

      def cookbook_loader_for(cookbook_path)
        loader = Chef::Cookbook::CookbookVersionLoader.new(cookbook_path, chefignore_for(cookbook_path))
        loader.load!
        loader
      end

      def chefignore_for(cookbook_path)
        Chef::Cookbook::Chefignore.new(File.join(cookbook_path, "chefignore"))
      end

      def create_policyfile_repo_item
        File.open(policyfile_repo_item_path, "wb+") do |f|
          f.print(FFI_Yajl::Encoder.encode(policyfile_lock.to_lock, pretty: true ))
        end
      end

      def create_policy_group_repo_item
        data = {
          "policies" => {
            policyfile_lock.name => {
              "revision_id" => policyfile_lock.revision_id,
            },
          },
        }

        File.open(policy_group_repo_item_path, "wb+") do |f|
          f.print(FFI_Yajl::Encoder.encode(data, pretty: true ))
        end
      end

      def copy_policyfile_lock
        File.open(lockfile_staging_path, "wb+") do |f|
          f.print(FFI_Yajl::Encoder.encode(policyfile_lock.to_lock, pretty: true ))
        end
      end

      def create_client_rb
        File.open(client_rb_staging_path, "wb+") do |f|
          f.print( <<~CONFIG )
            ### Chef Client Configuration ###
            # The settings in this file will configure chef to apply the exported policy in
            # this directory. To use it, run:
            #
            # chef-client -z
            #

            policy_name '#{policy_name}'
            policy_group 'local'

            use_policyfile true
            policy_document_native_api true

            # In order to use this repo, you need a version of Chef Client and Chef Zero
            # that supports policyfile "native mode" APIs:
            current_version = Gem::Version.new(Chef::VERSION)
            unless Gem::Requirement.new(">= 12.7").satisfied_by?(current_version)
              puts("!" * 80)
              puts(<<-MESSAGE)
            This Chef Repo requires features introduced in Chef 12.7, but you are using
            Chef \#{Chef::VERSION}. Please upgrade to Chef 12.7 or later.
            MESSAGE
              puts("!" * 80)
              exit!(1)
            end

          CONFIG
        end
      end

      def create_readme_md
        File.open(readme_staging_path, "wb+") do |f|
          f.print( <<~README )
            # Exported Chef Repository for Policy '#{policy_name}'

            Policy revision: #{policyfile_lock.revision_id}

            This directory contains all the cookbooks and configuration necessary for Chef
            to converge a system using this exported policy. To converge a system with the
            exported policy, use a privileged account to run `chef-client -z` from the
            directory containing the exported policy.

            ## Contents:

            ### Policyfile.lock.json

            A copy of the exported policy, used by the `chef push-archive` command.

            ### .chef/config.rb

            A configuration file for Chef Client. This file configures Chef Client to use
            the correct `policy_name` and `policy_group` for this exported repository. Chef
            Client will use this configuration automatically if you've set your working
            directory properly.

            ### cookbook_artifacts/

            All of the cookbooks required by the policy will be stored in this directory.

            ### policies/

            A different copy of the exported policy, used by the `chef-client` command.

            ### policy_groups/

            Policy groups are used by Chef Server to manage multiple revisions of the same
            policy. However, exported policies contain only a single policy revision, so
            this policy group name is hardcoded to "local" and should not be changed.

          README
        end
      end

      def mv_staged_repo
        # If we got here, either these dirs are empty/don't exist or force is
        # set to true.
        FileUtils.rm_rf(cookbook_artifacts_dir)
        FileUtils.rm_rf(policies_dir)
        FileUtils.rm_rf(policy_groups_dir)
        FileUtils.rm_rf(dot_chef_dir)

        FileUtils.mv(cookbook_artifacts_staging_dir, export_dir)
        FileUtils.mv(policies_staging_dir, export_dir)
        FileUtils.mv(policy_groups_staging_dir, export_dir)
        FileUtils.mv(lockfile_staging_path, export_dir)
        FileUtils.mv(dot_chef_staging_dir, export_dir)
        FileUtils.mv(readme_staging_path, export_dir)
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

      def assert_export_dir_clean!
        if !force_export? && !conflicting_fs_entries.empty? && !archive?
          msg = "Export dir (#{export_dir}) not clean. Refusing to export. (Conflicting files: #{conflicting_fs_entries.join(', ')})"
          raise ExportDirNotEmpty, msg
        end
      end

      def force_export?
        @force_export
      end

      def conflicting_fs_entries
        Dir.glob(File.join(cookbook_artifacts_dir, "*")) +
          Dir.glob(File.join(policies_dir, "*")) +
          Dir.glob(File.join(policy_groups_dir, "*")) +
          Dir.glob(File.join(export_dir, "Policyfile.lock.json"))
      end

      def cookbook_artifacts_dir
        File.join(export_dir, "cookbook_artifacts")
      end

      def policies_dir
        File.join(export_dir, "policies")
      end

      def policy_groups_dir
        File.join(export_dir, "policy_groups")
      end

      def dot_chef_dir
        File.join(export_dir, ".chef")
      end

      def policyfile_repo_item_path
        basename = "#{policyfile_lock.name}-#{policyfile_lock.revision_id}"
        File.join(staging_dir, "policies", "#{basename}.json")
      end

      def policy_group_repo_item_path
        File.join(staging_dir, "policy_groups", "local.json")
      end

      def dot_chef_staging_dir
        File.join(staging_dir, ".chef")
      end

      def cookbook_artifacts_staging_dir
        File.join(staging_dir, "cookbook_artifacts")
      end

      def policies_staging_dir
        File.join(staging_dir, "policies")
      end

      def policy_groups_staging_dir
        File.join(staging_dir, "policy_groups")
      end

      def lockfile_staging_path
        File.join(staging_dir, "Policyfile.lock.json")
      end

      def client_rb_staging_path
        File.join(dot_chef_staging_dir, "config.rb")
      end

      def readme_staging_path
        File.join(staging_dir, "README.md")
      end

    end

  end
end
