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

require "chef-dk/helpers"
require "chef-dk/service_exceptions"
require "chef-dk/policyfile_compiler"
require "chef-dk/policyfile/storage_config"
require "chef-dk/policyfile_lock"

module ChefDK
  module PolicyfileServices

    class Install

      include Policyfile::StorageConfigDelegation
      include ChefDK::Helpers

      attr_reader :ui
      attr_reader :storage_config
      attr_reader :overwrite
      attr_reader :chef_config

      def initialize(policyfile: nil, ui: nil, root_dir: nil, overwrite: false, config: nil)
        @ui = ui
        @overwrite = overwrite
        @chef_config = config

        policyfile_rel_path = policyfile || "Policyfile.rb"
        policyfile_full_path = File.expand_path(policyfile_rel_path, root_dir)
        @storage_config = Policyfile::StorageConfig.new.use_policyfile(policyfile_full_path)

        @policyfile_content = nil
        @policyfile_compiler = nil
      end

      def run(cookbooks_to_update = [])
        unless File.exist?(policyfile_expanded_path)
          # TODO: suggest next step. Add a generator/init command? Specify path to Policyfile.rb?
          # See card CC-232
          raise PolicyfileNotFound, "Policyfile not found at path #{policyfile_expanded_path}"
        end

        if installing_from_lock?
          install_from_lock
        elsif cookbooks_to_update.empty? # means update everything
          generate_lock_and_install
        else
          update_lock_and_install(cookbooks_to_update)
        end
      end

      def policyfile_content
        @policyfile_content ||= IO.read(policyfile_expanded_path)
      end

      def policyfile_compiler
        @policyfile_compiler ||= ChefDK::PolicyfileCompiler.evaluate(policyfile_content, policyfile_expanded_path, ui: ui, chef_config: chef_config)
      end

      def expanded_run_list
        policyfile_compiler.expanded_run_list.to_s
      end

      def policyfile_lock_content
        @policyfile_lock_content ||= IO.read(policyfile_lock_expanded_path) if File.exist?(policyfile_lock_expanded_path)
      end

      def policyfile_lock
        return nil if policyfile_lock_content.nil?
        @policyfile_lock ||= begin
          lock_data = FFI_Yajl::Parser.new.parse(policyfile_lock_content)
          PolicyfileLock.new(storage_config, ui: ui).build_from_lock_data(lock_data)
        end
      end

      def generate_lock_and_install
        policyfile_compiler.error!

        ui.msg "Building policy #{policyfile_compiler.name}"
        ui.msg "Expanded run list: " + expanded_run_list + "\n"

        ui.msg "Caching Cookbooks..."

        policyfile_compiler.install

        lock_data = policyfile_compiler.lock.to_lock

        with_file(policyfile_lock_expanded_path) do |f|
          f.print(FFI_Yajl::Encoder.encode(lock_data, pretty: true ))
        end

        ui.msg ""

        ui.msg "Lockfile written to #{policyfile_lock_expanded_path}"
        ui.msg "Policy revision id: #{policyfile_lock.revision_id}"
      rescue => error
        raise PolicyfileInstallError.new("Failed to generate Policyfile.lock", error)
      end

      def update_lock_and_install(cookbooks_to_update)
        ui.msg "Updating #{cookbooks_to_update.join(',')} cookbooks"
        to_update = policyfile_lock.solution_dependencies.transitive_deps(cookbooks_to_update)
        prepare_constraints_for_update(to_update)
        prepare_constraints_for_policies
        generate_lock_and_install
      end

      def prepare_constraints_for_update(to_update)
        ui.msg "Will relax constraints on:"
        to_update.each do |ck|
          ui.msg " - #{ck}"
        end

        policyfile_lock.cookbook_locks.each do |ck_name, location_spec|
          next if to_update.include?(ck_name)
          # we need to feed policyfile_compiler.cookbook_location_spec_for with a CookbookLocationSpecification
          policyfile_compiler.dsl.cookbook_location_specs[ck_name] = Policyfile::CookbookLocationSpecification.new(
            ck_name,
            Semverse::Constraint.new("=#{location_spec.version}"),
            location_spec.source_options,
            location_spec.storage_config
          )
        end
      end

      def prepare_constraints_for_policies
        Policyfile::LockApplier.
          new(policyfile_lock, policyfile_compiler).
          apply!
      end

      def install_from_lock
        ui.msg "Installing cookbooks from lock"

        policyfile_lock.install_cookbooks
      rescue => error
        raise PolicyfileInstallError.new("Failed to install cookbooks from lockfile", error)
      end

      def installing_from_lock?
        !@overwrite && File.exist?(policyfile_lock_expanded_path)
      end

    end
  end
end
