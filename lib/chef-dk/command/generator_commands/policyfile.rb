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

      class Policyfile < Base

        banner "Usage: chef generate policyfile [NAME] [options]"

        options.merge!(SharedGeneratorOptions.options)

        attr_reader :new_file_basename
        attr_reader :policyfile_dir

        def initialize(*args)
          super
          @params_valid = true
        end

        def recipe
          'policyfile'
        end

        def setup_context
          super
          Generator.add_attr_to_context(:policyfile_dir, policyfile_dir)
          Generator.add_attr_to_context(:new_file_basename, new_file_basename)
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
        end

        def read_and_validate_params
          arguments = parse_options(params)
          new_file_path =
            case arguments.size
            when 0
              "Policyfile"
            when 1
              arguments[0]
            else
              @params_valid = false
              return false
            end
          @new_file_basename = File.basename(new_file_path, ".rb")
          @policyfile_dir = File.expand_path(File.dirname(new_file_path))
        end

        def params_valid?
          @params_valid
        end

      end
    end
  end
end
