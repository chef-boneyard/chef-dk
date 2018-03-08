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

require "chef-dk/command/generator_commands/base"

module ChefDK
  module Command
    module GeneratorCommands

      # ## App
      # chef generate app path/to/basename --generator-cookbook=path/to/generator
      #
      # Generates a full "application" directory structure.
      class App < Base

        banner "Usage: chef generate app NAME [options]"

        attr_reader :errors
        attr_reader :app_name_or_path

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          @params_valid = true
          @app_name = nil
          super
        end

        def run
          read_and_validate_params
          if params_valid?
            setup_context
            chef_runner.converge
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
          Generator.add_attr_to_context(:app_root, app_root)
          Generator.add_attr_to_context(:app_name, app_name)
          Generator.add_attr_to_context(:cookbook_root, cookbook_root)
          Generator.add_attr_to_context(:cookbook_name, cookbook_name)
          Generator.add_attr_to_context(:recipe_name, recipe_name)
        end

        def recipe
          "app"
        end

        def recipe_name
          "default"
        end

        def app_name
          File.basename(app_full_path)
        end

        def app_root
          File.dirname(app_full_path)
        end

        def cookbook_root
          File.join(app_full_path, "cookbooks")
        end

        def cookbook_name
          app_name
        end

        def app_full_path
          File.expand_path(app_name_or_path, Dir.pwd)
        end

        def read_and_validate_params
          arguments = parse_options(params)
          @app_name_or_path = arguments[0]
          @params_valid = false unless @app_name_or_path
        end

        def params_valid?
          @params_valid
        end
      end
    end
  end
end
