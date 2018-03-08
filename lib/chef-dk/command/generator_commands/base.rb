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

require "chef-dk/configurable"
require "chef-dk/command/generator_commands"

require "chef-dk/command/generator_commands/chef_exts/recipe_dsl_ext"
require "chef-dk/command/generator_commands/chef_exts/generator_desc_resource"

module ChefDK
  module Command
    module GeneratorCommands
      # ## Base
      #
      # Base class for `chef generate` subcommands. Contains basic behaviors
      # for setting up the generator context, detecting git, and launching a
      # chef converge.
      #
      # The behavior of the generators is largely delegated to a chef cookbook.
      # The default implementation is the `code_generator` cookbook in
      # chef-dk/skeletons/code_generator.
      class Base < Command::Base

        include Configurable

        attr_reader :params

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          super()
          @params = params

          @generator_cookbook_path = nil
          @generator_cookbook_name = nil
        end

        # An instance of ChefRunner. Calling ChefRunner#converge will trigger
        # convergence and generate the desired code.
        def chef_runner
          @chef_runner ||= ChefRunner.new(generator_cookbook_path, ["recipe[#{generator_cookbook_name}::#{recipe}]"])
        end

        # Path to the directory where the code_generator cookbook is located.
        def generator_cookbook_path
          detect_generator_cookbook_name_and_path! unless @generator_cookbook_path
          @generator_cookbook_path
        end

        def generator_cookbook_name
          detect_generator_cookbook_name_and_path! unless @generator_cookbook_name
          @generator_cookbook_name
        end

        # Sets git related generator_context values.
        def setup_context
          apply_generator_values_from_config
          Generator.add_attr_to_context(:have_git, have_git?)
          Generator.add_attr_to_context(:skip_git_init, false)
          config.each do |k, v|
            Generator.add_attr_to_context(k, v)
          end
          # inject the arbitrary args supplied on cmdline, default = []
          config[:generator_arg].each do |k, v|
            Generator.add_attr_to_context(k, v)
          end
        end

        # Checks the `PATH` for the presence of a `git` (or `git.exe`, on
        # windows) executable.
        def have_git?
          path = ENV["PATH"] || ""
          paths = path.split(File::PATH_SEPARATOR)
          exts = [RbConfig::CONFIG["EXEEXT"]]
          exts.concat(ENV["PATHEXT"].split(";")) unless ENV["PATHEXT"].nil?
          paths.any? do |bin_path|
            exts.any? do |ext|
              File.exist?(File.join(bin_path, "git#{ext}"))
            end
          end
        end

        private

        # Inspects the `config[:generator_cookbook]` option to determine the
        # generator_cookbook_name and generator_cookbook_path. There are two
        # supported ways this can work:
        #
        # * `config[:generator_cookbook]` is the full path to the generator
        # cookbook. In this case, the last path component is the cookbook name,
        # and the parent directory is the cookbook path
        # * `config[:generator_cookbook]` is the path to a directory that
        # contains a cookbook named "code_generator" (DEPRECATED). This is how
        # the `--generator-cookbook` feature was originally written, so we
        # support this for backwards compatibility. This way has poor UX and
        # we'd like to get rid of it, so a warning is printed in this case.
        def detect_generator_cookbook_name_and_path!
          given_path = generator_cookbook_option
          code_generator_subdir = File.join(given_path, "code_generator")
          if File.directory?(code_generator_subdir)
            @generator_cookbook_name = "code_generator"
            @generator_cookbook_path = given_path
            err("WARN: Please configure the generator cookbook by giving the full path to the desired cookbook (like '#{code_generator_subdir}')")
          else
            @generator_cookbook_name = File.basename(given_path)
            @generator_cookbook_path = File.dirname(given_path)
          end
        end

        def generator_cookbook_option
          config[:generator_cookbook] || chefdk_config.generator_cookbook
        end

        # Load any values that were not defined via cli switches from Chef
        # configuration
        #
        def apply_generator_values_from_config
          config[:copyright_holder] ||= coerce_generator_copyright_holder
          config[:email] ||= coerce_generator_email
          config[:license] ||= coerce_generator_license
        end

        def coerce_generator_copyright_holder
          generator_config.copyright_holder ||
            knife_config.cookbook_copyright ||
            "The Authors"
        end

        def coerce_generator_email
          generator_config.email ||
            knife_config.cookbook_email ||
            "you@example.com"
        end

        def coerce_generator_license
          generator_config.license ||
            knife_config.cookbook_license ||
            "all_rights"
        end
      end
    end
  end
end
