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

require 'chef-dk/command/base'
require 'chef-dk/chef_runner'

module ChefDK

  module Generator

    class AppConfig
      attr_accessor :root
      attr_accessor :cookbook_name
      attr_accessor :author_name
      attr_accessor :author_email
      attr_accessor :license_description
      attr_accessor :license_text
    end

    def self.app
      @app ||= AppConfig.new
    end

    module TemplateHelper

      def self.delegate_to_app_config(name)
        define_method(name) do
          ChefDK::Generator.app.public_send(name)
        end
      end

      # delegate all the attributes of app_config
      delegate_to_app_config :root
      delegate_to_app_config :cookbook_name
      delegate_to_app_config :author_name
      delegate_to_app_config :author_email
      delegate_to_app_config :license_description
      delegate_to_app_config :license_text

    end

  end

  module Command
    class Generate < Base

      # chef generate app path/to/basename --skel=path/to/skeleton --example-code
      # chef generate cookbook path/to/basename --skel=path/to/skeleton --example-code
      # chef generate template name [path/to/cookbook_root] (inferred from cwd) --from=source_file
      # chef generate file name [path/to/cookbook_root] (inferred from cwd) --from=source_file
      # chef generate lwrp name [path/to/cookbook_root] (inferred from cwd)
      # chef generate attr name [path/to/cookbook_root] (inferred from cwd)

      attr_reader :run_context

      def initialize(*args)
        super
        @run_context = nil
      end

      def run(params)
        setup_app
        run_chef
        return 0
      end

      def run_chef
        chef_runner.converge
      end

      def chef_runner
        @chef_runner ||= ChefRunner.new(cookbook_path, ["code_generator::cookbook"])
      end

      def cookbook_path
        File.expand_path("../../skeletons", __FILE__)
      end

      def setup_app
        Generator.app.root = File.join(Dir.pwd, "demo-#{Time.now.to_i}") #FIXME
      end

      def setup_chef
        @run_context = policy_builder.setup_run_context
      end

    end
  end
end
