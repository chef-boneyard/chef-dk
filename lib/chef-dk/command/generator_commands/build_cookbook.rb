#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

require "chef-dk/command/generator_commands/base"

module ChefDK
  module Command
    module GeneratorCommands

      class BuildCookbook < Base

        banner "Usage: chef generate build-cookbook NAME [options]"

        attr_reader :errors

        attr_reader :cookbook_name_or_path

        option :pipeline,
          long: "--pipeline PIPELINE",
          description: "Use PIPELINE to set target branch to something other than master for the build_cookbook",
          default: "master"

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          @params_valid = true
          @cookbook_name = nil
          super
        end

        def run
          read_and_validate_params
          if params_valid?
            setup_context
            chef_runner.converge
            0
          else
            err(opt_parser)
            1
          end
        rescue ChefDK::ChefRunnerError => e
          err("ERROR: #{e}")
          1
        end

        def setup_context
          super
          Generator.add_attr_to_context(:delivery_project_dir, delivery_project_dir)

          Generator.add_attr_to_context(:delivery_project_git_initialized, delivery_project_git_initialized?)
          Generator.add_attr_to_context(:build_cookbook_parent_is_cookbook, build_cookbook_parent_is_cookbook?)

          Generator.add_attr_to_context(:pipeline, pipeline)
        end

        def pipeline
          config[:pipeline]
        end

        def recipe
          "build_cookbook"
        end

        def build_cookbook_parent_is_cookbook?
          metadata_json_path = File.join(delivery_project_dir, "metadata.json")
          metadata_rb_path = File.join(delivery_project_dir, "metadata.rb")

          File.exist?(metadata_json_path) || File.exist?(metadata_rb_path)
        end

        def delivery_project_dir
          project_dir = File.expand_path(cookbook_name_or_path, Dir.pwd)
          # Detect if we were invoked with arguments like
          #
          #     chef generate build-cookbook project/.delivery/build_cookbook
          #
          # If so, normalize paths so we don't make a directory structure like
          # `.delivery/.delivery/build_cookbook`.
          #
          # Note that we don't check the name of the build cookbook the user
          # asked for and we hard-code to naming it "build_cookbook". We also
          # don't catch the case that the user requested something like
          # `project/.delivery/build_cookbook/extra-thing-that-shouldn't-be-here`
          Pathname.new(project_dir).ascend do |dir|
            if File.basename(dir) == ".delivery"
              project_dir = File.dirname(dir)
            end
          end
          project_dir
        end

        def delivery_project_git_initialized?
          File.exist?(File.join(delivery_project_dir, ".git"))
        end

        def read_and_validate_params
          arguments = parse_options(params)
          @cookbook_name_or_path = arguments[0]
          unless @cookbook_name_or_path
            @params_valid = false
          end
        end

        def params_valid?
          @params_valid
        end

      end
    end
  end
end
