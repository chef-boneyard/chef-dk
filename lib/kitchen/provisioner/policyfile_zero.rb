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
# the version of mixlib-shellout to use. Kitchen currently locked at 1.x,
# chef-dk is on 2.x
require 'chef-dk/policyfile_services/export_repo'

module Kitchen

  module Provisioner

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
      default_config :ruby_bindir, "/opt/chef/embedded/bin"

      # Policyfile mode does not support the `-j dna.json` option to
      # `chef-client`.
      default_config :json_attributes, false
      default_config :chef_zero_port, 8889

      default_config :chef_client_path do |provisioner|
        File.join(provisioner[:chef_omnibus_root], provisioner.shell.chef_client_file)
      end

      # Emit a warning that Policyfile stuff is still experimental.
      #
      # (see Base#finalize_config!)
      def finalize_config!(*args)
        super
        banner("Using experimental policyfile mode for chef-client")
        warn("The Policyfile feature is under active development.")
        warn("For best results, always use the latest chef-client version")
      end

      # (see Base#create_sandbox)
      def create_sandbox
        super
        prepare_validation_pem
        prepare_client_rb
      end

      # (see Base#run_command)
      def run_command
        level = config[:log_level] == :info ? :auto : config[:log_level]
        chef_client_bin = shell.sudo(config[:chef_client_path])

        cmd = "#{chef_client_bin} --local-mode"
        args = [
          "--config #{config[:root_path]}/client.rb",
          "--log_level #{level}",
          "--force-formatter",
          "--no-color"
        ]
        if config[:chef_zero_port]
          args <<  "--chef-zero-port #{config[:chef_zero_port]}"
        end
        if config[:log_file]
          args << "--logfile #{config[:log_file]}"
        end

        shell.wrap_command([cmd, *args].join(" "))
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
        @policy_exporter ||= ChefDK::PolicyfileServices::ExportRepo.new(export_dir: sandbox_path)
      end

      # Writes a fake (but valid) validation.pem into the sandbox directory.
      #
      # @api private
      def prepare_validation_pem
        info("Preparing validation.pem")
        debug("Using a dummy validation.pem")

        source = File.join(Kitchen.source_root, %w[support dummy-validation.pem])
        FileUtils.cp(source, File.join(sandbox_path, "validation.pem"))
      end

      # Writes a client.rb configuration file to the sandbox directory.
      #
      # @api private
      def prepare_client_rb
        data = default_config_rb.merge(config[:client_rb])

        data["use_policyfile"] = true
        data["versioned_cookbooks"] = true
        data["deployment_group"] = "#{policy_exporter.policy_name}-local"

        info("Preparing client.rb")
        debug("Creating client.rb from #{data.inspect}")

        File.open(File.join(sandbox_path, "client.rb"), "wb") do |file|
          file.write(format_config_file(data))
        end
      end

    end
  end
end
