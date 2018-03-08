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
      # ## CookbookCodeFile
      # A base class for generators that add individual files to existing
      # cookbooks.
      class CookbookCodeFile < Base

        attr_reader :errors
        attr_reader :cookbook_path
        attr_reader :new_file_basename

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          @params_valid = true
          @cookbook_full_path = nil
          @new_file_basename = nil
          @errors = []
          @params = params
          super
        end

        def run
          read_and_validate_params
          if params_valid?
            setup_context
            chef_runner.converge
          else
            errors.each { |error| err("Error: #{error}") }
            parse_options(params)
            msg(opt_parser)
            1
          end
        end

        def setup_context
          super
          Generator.add_attr_to_context(:cookbook_root, cookbook_root)
          Generator.add_attr_to_context(:cookbook_name, cookbook_name)
          Generator.add_attr_to_context(:new_file_basename, new_file_basename)
          Generator.add_attr_to_context(:recipe_name, new_file_basename)
        end

        def cookbook_root
          File.dirname(cookbook_path)
        end

        def cookbook_name
          File.basename(cookbook_path)
        end

        def read_and_validate_params
          arguments = parse_options(params)
          case arguments.size
          when 1
            @new_file_basename = arguments[0]
            @cookbook_path = Dir.pwd
            validate_cookbook_path
          when 2
            @cookbook_path = arguments[0]
            @new_file_basename = arguments[1]
          else
            @params_valid = false
          end
        end

        def validate_cookbook_path
          unless File.file?(File.join(cookbook_path, "metadata.rb"))
            @errors << "Directory #{cookbook_path} is not a cookbook"
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
