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

      # ## Repo
      # chef generate repo path/to/basename --generator-cookbook=path/to/generator --policy-only
      #
      # Generates a full "chef-repo" directory structure.
      class Repo < Base

        banner "Usage: chef generate repo NAME [options]"

        attr_reader :errors
        attr_reader :repo_name_or_path

        option :policy_only,
          short:        "-p",
          long:         "--policy-only",
          description:  "Create a repository for policy only, not cookbooks",
          default:      false

        option :roles,
          short:        "-r",
          long:         "--roles",
          description:  "Create roles and environments directories instead of using policyfiles",
          default:      nil

        option :policy,
          short:        "-P",
          long:         "--policy",
          description:  "Use policyfiles instead of Berkshelf",
          boolean:      true,
          default:      nil

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          @params_valid = true
          @repo_name = nil
          @use_roles = true
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
        end

        def setup_context
          super
          Generator.add_attr_to_context(:repo_root, repo_root)
          Generator.add_attr_to_context(:repo_name, repo_name)
          Generator.add_attr_to_context(:use_roles, use_roles?)
        end

        def recipe
          "repo"
        end

        def repo_name
          File.basename(repo_full_path)
        end

        def repo_root
          File.dirname(repo_full_path)
        end

        def repo_full_path
          File.expand_path(repo_name_or_path, Dir.pwd)
        end

        def use_roles?
          @use_roles
        end

        def read_and_validate_params
          arguments = parse_options(params)
          @repo_name_or_path = arguments[0]
          unless @repo_name_or_path
            @params_valid = false
          end
          if !config[:roles].nil? && !config[:policy].nil?
            err("Roles and Policyfiles are exclusive. Please only select one.")
            @params_valid = false
          end
          if config[:policy]
            @use_roles = false
          end
        end

        def params_valid?
          @params_valid
        end
      end
    end
  end
end
