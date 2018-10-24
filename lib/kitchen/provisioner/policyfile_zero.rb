# -*- encoding: utf-8 -*-
#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2013, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "kitchen/provisioner/chef_base"

# TODO: chef-dk and kitchen can only co-exist if kitchen and chef-dk agree on
# the version of mixlib-shellout to use. Kitchen currently locked at 1.4,
# chef-dk is on 2.x
require "chef-dk/policyfile_services/export_repo"

module Kitchen

  module Provisioner

    class Base

      # PolicyfileZero needs to access the base behavior of creating the
      # sandbox directory without invoking the behavior of
      # ChefBase#create_sandbox, because that will trigger the use of
      # Chef::CommonSandbox, which we need to override.
      alias_method :create_sandbox_directory, :create_sandbox

    end

    class PolicyfileSandbox < Chef::CommonSandbox

      # Stub #prepare_cookbooks because we have implemented this in the
      # provisioner, below. If a Berksfile is present, the default
      # implementation will try to run Berkshelf, which can lead to dependency
      # issues since berks is not yet using Solve 2.x. See also
      # PolicyfileZero#load_needed_dependencies! which is stubbed to prevent
      # berks from loading.
      def prepare_cookbooks
      end

    end

    # Policyfile + Chef Zero provisioner.
    #
    # @author Daniel DeLeo <dan@chef.io>
    class PolicyfileZero < ChefBase

      # This provsioner will forcibly set the following config options:
      # * `use_policyfile`: `true`
      # * `versioned_cookbooks`: `true`
      # * `deployment_group`: `POLICY_NAME-local`
      # Since it makes no sense to modify these, they are hardcoded elsewhere.
      default_config :client_rb, {}
      default_config :json_attributes, true
      default_config :named_run_list, nil
      default_config :chef_zero_host, nil
      default_config :chef_zero_port, 8889
      default_config :policyfile, "Policyfile.rb"

      default_config :chef_client_path do |provisioner|
        provisioner
          .remote_path_join(%W{#{provisioner[:chef_omnibus_root]} bin chef-client})
          .tap { |path| path.concat(".bat") if provisioner.windows_os? }
      end

      default_config :ruby_bindir do |provisioner|
        provisioner
          .remote_path_join(%W{#{provisioner[:chef_omnibus_root]} embedded bin})
      end

      # (see Base#finalize_config!)
      def finalize_config!(*args)
        super
        banner("Using policyfile mode for chef-client")
      end

      # (see Base#create_sandbox)
      def create_sandbox
        create_sandbox_directory
        PolicyfileSandbox.new(config, sandbox_path, instance).populate
        prepare_cookbooks
        prepare_validation_pem
        prepare_client_rb
      end

      # (see Base#run_command)
      def run_command
        level = config[:log_level] == :info ? :auto : config[:log_level]

        cmd = "#{sudo(config[:chef_client_path])} --local-mode"
          .tap { |str| str.insert(0, "& ") if powershell_shell? }

        args = [
          "--config #{config[:root_path]}/client.rb",
          "--log_level #{level}",
          "--force-formatter",
          "--no-color",
        ]
        if config[:chef_zero_port]
          args << "--chef-zero-port #{config[:chef_zero_port]}"
        end
        if config[:log_file]
          args << "--logfile #{config[:log_file]}"
        end

        if config[:named_run_list]
          args << "--named-run-list #{config[:named_run_list]}"
        end

        wrap_shell_code(
          [cmd, *args].join(" ")
          .tap { |str| str.insert(0, reload_ps1_path) if windows_os? }
        )
      end

      # We don't want to load Berkshelf or Librarian; Policyfile is managing
      # dependencies, so these can only cause trouble.
      def load_needed_dependencies!
      end

      private

      # Overrides behavior of parent class so that dna.json isn't created; we
      # don't need it.
      #
      # @api private
      def prepare_json
      end

      # Copies the policyfile's cookbooks to the sandbox.
      #
      # @api private
      def prepare_cookbooks
        Kitchen.mutex.synchronize do
          policy_exporter.run
        end
      end

      # An instance of ChefDK::PolicyfileServices::ExportRepo, configured with
      # the sandbox path. Calling `#run` on this copies the cookbooks to the
      # sandbox. Calling `#policy_name` returns the policy's name.
      #
      # @api private
      def policy_exporter
        # Must force this because TK by default copies the current cookbook to the sandbox
        # See ChefDK::PolicyfileServices::ExportRepo#assert_export_dir_clean!
        @policy_exporter ||= ChefDK::PolicyfileServices::ExportRepo.new(policyfile: config[:policyfile],
                                                                        export_dir: sandbox_path,
                                                                        force: true)
      end

      # Writes a fake (but valid) validation.pem into the sandbox directory.
      #
      # @api private
      def prepare_validation_pem
        info("Preparing validation.pem")
        debug("Using a dummy validation.pem")

        source = File.join(Kitchen.source_root, %w{support dummy-validation.pem})
        FileUtils.cp(source, File.join(sandbox_path, "validation.pem"))
      end

      # Writes a client.rb configuration file to the sandbox directory.
      #
      # @api private
      def prepare_client_rb
        data = default_config_rb.merge(config[:client_rb])

        data["use_policyfile"] = true
        data["versioned_cookbooks"] = true
        data["policy_name"] = policy_exporter.policy_name
        data["policy_group"] = "local"
        data["policy_document_native_api"] = true

        info("Preparing client.rb")
        debug("Creating client.rb from #{data.inspect}")

        File.open(File.join(sandbox_path, "client.rb"), "wb") do |file|
          file.write(format_config_file(data))
        end
      end

    end
  end
end
