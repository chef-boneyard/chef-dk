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

        option :berks,
          short:       "-b",
          long:        "--berks",
          description: "Generate cookbooks with berkshelf integration",
          boolean:     true,
          default:     nil

        option :kitchen,
          long:        "--kitchen CONFIGURATION",
          description: "Generate cookbooks with a specific kitchen configuration (dokken|vagrant) - defaults to vagrant",
          default:     "vagrant"

        option :policy,
          short:        "-P",
          long:         "--policy",
          description:  "Use policyfiles instead of Berkshelf",
          boolean:      true,
          default:      nil

        option :delivery,
          short:        "-d",
          long:         "--delivery",
          description:  "This option has no effect and exists only for compatibility with past releases",
          boolean:      true,
          default:      true

        option :verbose,
          short:        "-V",
          long:         "--verbose",
          description:  "Show detailed output from the generator",
          boolean:      true,
          default:      false

        option :pipeline,
          long: "--pipeline PIPELINE",
          description: "Use PIPELINE to set target branch to something other than master for the build_cookbook",
          default: "master"

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          @params_valid = true
          @cookbook_name = nil
          @berks_mode = true
          @enable_delivery = true
          @verbose = false
          super
        end

        def run
          read_and_validate_params
          if params_valid?
            setup_context
            msg("Generating cookbook #{cookbook_name}")
            chef_runner.converge
            msg("")
            emit_post_create_message
            0
          else
            err(opt_parser)
            1
          end
        rescue ChefDK::ChefRunnerError => e
          err("ERROR: #{e}")
          1
        end

        def emit_post_create_message
          if have_delivery_config?
            msg("Your cookbook is ready. To setup the pipeline, type `cd #{cookbook_name_or_path}`, then run `delivery init`")
          else
            msg("Your cookbook is ready. Type `cd #{cookbook_name_or_path}` to enter it.")
            msg("\nThere are several commands you can run to get started locally developing and testing your cookbook.")
            msg("Type `delivery local --help` to see a full list.")
            msg("\nWhy not start by writing a test? Tests for the default recipe are stored at:\n")
            msg("test/integration/default/default_test.rb")
            msg("\nIf you'd prefer to dive right in, the default recipe can be found at:")
            msg("\nrecipes/default.rb\n")
          end
        end

        def setup_context
          super
          Generator.add_attr_to_context(:skip_git_init, cookbook_path_in_git_repo?)
          Generator.add_attr_to_context(:cookbook_root, cookbook_root)
          Generator.add_attr_to_context(:cookbook_name, cookbook_name)
          Generator.add_attr_to_context(:recipe_name, recipe_name)
          Generator.add_attr_to_context(:include_chef_repo_source, false)
          Generator.add_attr_to_context(:policy_name, policy_name)
          Generator.add_attr_to_context(:policy_run_list, policy_run_list)
          Generator.add_attr_to_context(:policy_local_cookbook, ".")

          Generator.add_attr_to_context(:enable_delivery, enable_delivery?)
          Generator.add_attr_to_context(:delivery_project_dir, cookbook_full_path)
          Generator.add_attr_to_context(:build_cookbook_parent_is_cookbook, true)
          Generator.add_attr_to_context(:delivery_project_git_initialized, have_git? && !cookbook_path_in_git_repo?)

          Generator.add_attr_to_context(:verbose, verbose?)

          Generator.add_attr_to_context(:use_berkshelf, berks_mode?)
          Generator.add_attr_to_context(:pipeline, pipeline)
          Generator.add_attr_to_context(:kitchen, kitchen)
        end

        def kitchen
          config[:kitchen]
        end

        def pipeline
          config[:pipeline]
        end

        def policy_name
          cookbook_name
        end

        def policy_run_list
          "#{cookbook_name}::#{recipe_name}"
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

        def berks_mode?
          @berks_mode
        end

        def enable_delivery?
          @enable_delivery
        end

        def verbose?
          @verbose
        end

        def have_delivery_config?
          # delivery-cli's logic is to look recursively upward for
          # .delivery/cli.toml starting from pwd:
          # https://github.com/chef/delivery-cli/blob/22cbef3987ebd0aee98405b7e161a100edc87e49/src/delivery/config/mod.rs#L225-L247

          path_to_check = File.expand_path(Dir.pwd)
          result = false

          Pathname.new(path_to_check).ascend do |path|
            if contains_delivery_cli_toml?(path)
              result = true
              break
            end
          end

          result
        end

        def contains_delivery_cli_toml?(path)
          delivery_cli_path = path.join(".delivery/cli.toml")
          delivery_cli_path.exist?
        end

        def read_and_validate_params
          arguments = parse_options(params)
          @cookbook_name_or_path = arguments[0]
          if !@cookbook_name_or_path
            @params_valid = false
          elsif /-/ =~ File.basename(@cookbook_name_or_path)
            msg("Hyphens are discouraged in cookbook names as they may cause problems with custom resources. See https://docs.chef.io/ctl_chef.html#chef-generate-cookbook for more information.")
          end

          if config[:berks] && config[:policy]
            err("Berkshelf and Policyfiles are mutually exclusive. Please specify only one.")
            @params_valid = false
          end

          if config[:policy]
            @berks_mode = false
          end

          if config[:verbose]
            @verbose = true
          end

          true
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
