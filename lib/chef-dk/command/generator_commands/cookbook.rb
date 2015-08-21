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

require 'chef-dk/command/generator_commands/base'

module ChefDK
  module Command
    module GeneratorCommands

      # ## CookbookFile
      # chef generate cookbook path/to/basename --generator-cookbook=path/to/generator
      #
      # Generates a basic cookbook directory structure. Most file types are
      # omitted, the user is expected to add additional files as needed using
      # the relevant generators.
      class Cookbook < Base

        banner "Usage: chef generate cookbook NAME [options]"

        attr_reader :errors

        attr_reader :cookbook_name_or_path

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
          Generator.add_attr_to_context(:skip_git_init, cookbook_path_in_git_repo?)
          Generator.add_attr_to_context(:cookbook_root, cookbook_root)
          Generator.add_attr_to_context(:cookbook_name, cookbook_name)
          Generator.add_attr_to_context(:recipe_name, recipe_name)
        end

        def recipe
          "cookbook"
        end

        def recipe_name
          "default"
        end

        def cookbook_name
          File.basename(cookbook_full_path)
        end

        def cookbook_root
          File.dirname(cookbook_full_path)
        end

        def cookbook_full_path
          File.expand_path(cookbook_name_or_path, Dir.pwd)
        end

        def read_and_validate_params
          arguments = parse_options(params)
          @cookbook_name_or_path = arguments[0]
          @params_valid = false unless @cookbook_name_or_path
        end

        def params_valid?
          @params_valid
        end

        def cookbook_path_in_git_repo?
          Pathname.new(cookbook_full_path).ascend do |dir|
            return true if File.directory?(File.join(dir.to_s, ".git"))
          end
          false
        end
      end
    end
  end
end

