#
# Copyright:: Copyright (c) 2014-2018, Chef Software Inc.
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

      class Policyfile < Base

        banner "Usage: chef generate policyfile [NAME] [options]"

        options.merge!(SharedGeneratorOptions.options)

        attr_reader :new_file_basename
        attr_reader :policyfile_dir
        attr_reader :policy_name
        attr_reader :policy_run_list

        def initialize(*args)
          super
          @new_file_basename = nil
          @policyfile_dir = nil
          @policy_name = nil
          @policy_run_list = nil
          @params_valid = true
        end

        def recipe
          "policyfile"
        end

        def setup_context
          super
          Generator.add_attr_to_context(:policyfile_dir, policyfile_dir)
          Generator.add_attr_to_context(:new_file_basename, new_file_basename)
          Generator.add_attr_to_context(:include_chef_repo_source, chef_repo_mode?)
          Generator.add_attr_to_context(:policy_name, policy_name)
          Generator.add_attr_to_context(:policy_run_list, policy_run_list)
          Generator.add_attr_to_context(:policy_local_cookbook, nil)
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

          case arguments.size
          when 0
            if chef_repo_mode?
              err("ERROR: You must give a policy name when generating a policy in a chef-repo.")
              @params_valid = false
              return false
            else
              use_default_policy_settings
            end
          when 1
            derive_policy_settings_from_args(arguments[0])
          else
            @params_valid = false
            err("ERROR: too many arguments")
            return false
          end
        end

        private

        def use_default_policy_settings
          @new_file_basename = "Policyfile"
          @policy_name = "example-application-service"
          @policy_run_list = "example_cookbook::default"
          @policyfile_dir = Dir.pwd
        end

        def derive_policy_settings_from_args(new_file_path)
          @new_file_basename = File.basename(new_file_path, ".rb")
          @policy_name = @new_file_basename
          @policy_run_list = "#{policy_name}::default"
          given_policy_dirname = File.expand_path(File.dirname(new_file_path))
          @policyfile_dir =
            if chef_repo_mode? && (given_policy_dirname == Dir.pwd)
              File.expand_path("policyfiles")
            else
              given_policy_dirname
            end
        end

        def params_valid?
          @params_valid
        end

        def chef_repo_mode?
          File.exist?(File.expand_path(".chef-repo.txt"))
        end

      end
    end
  end
end
