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

require 'chef-dk/command/generator_commands'

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

        attr_reader :params

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          super()
          @params = params
        end

        # An instance of ChefRunner. Calling ChefRunner#converge will trigger
        # convergence and generate the desired code.
        def chef_runner
          @chef_runner ||= ChefRunner.new(generator_cookbook_path, ["code_generator::#{recipe}"])
        end

        # Path to the directory where the code_generator cookbook is located.
        # For now, this is hard coded to the 'skeletons' directory in this
        # repo.
        def generator_cookbook_path
          config[:generator_cookbook]
        end

        # Sets git related generator_context values.
        def setup_context
          Generator.context.have_git = have_git?
          Generator.context.skip_git_init = false
        end

        # Delegates to `Generator.context`, the singleton instance of
        # Generator::Context
        def generator_context
          Generator.context
        end

        # Checks the `PATH` for the presence of a `git` (or `git.exe`, on
        # windows) executable.
        def have_git?
          path = ENV["PATH"] || ""
          paths = path.split(File::PATH_SEPARATOR)
          paths.any? {|bin_path| File.exist?(File.join(bin_path, "git#{RbConfig::CONFIG['EXEEXT']}"))}
        end
      end
    end
  end
end

