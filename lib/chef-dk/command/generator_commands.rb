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

require 'mixlib/cli'
require 'rbconfig'
require 'pathname'
require 'chef-dk/command/base'
require 'chef-dk/chef_runner'
require 'chef-dk/generator'

module ChefDK
  module Command

    # ## SharedGeneratorOptions
    #
    # These CLI options are shared amongst the generator commands
    module SharedGeneratorOptions
      include Mixlib::CLI

      option :generator_cookbook,
        :short => "-g GENERATOR_COOKBOOK_PATH",
        :long  => "--generator-cookbook GENERATOR_COOKBOOK_PATH",
        :description => "Use GENERATOR_COOKBOOK_PATH for the code_generator cookbook",
        :default => File.expand_path("../../skeletons", __FILE__),
        :proc => Proc.new { |s| File.expand_path(s) },
        :on => :tail
    end

    # ## GeneratorCommands
    #
    # This module is the namespace for all subcommands of `chef generate`
    module GeneratorCommands

      def self.build(class_name, params)
        const_get(class_name).new(params)
      end

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
            msg(banner)
            1
          end
        end

        def setup_context
          super
          generator_context.app_root = app_root
          generator_context.app_name = app_name
        end

        def recipe
          "app"
        end

        def app_name
          File.basename(app_full_path)
        end

        def app_root
          File.dirname(app_full_path)
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
            msg(banner)
            1
          end
        end

        def setup_context
          super
          generator_context.skip_git_init = cookbook_path_in_git_repo?
          generator_context.cookbook_root = cookbook_root
          generator_context.cookbook_name = cookbook_name
        end

        def recipe
          "cookbook"
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
          super
        end

        def run
          read_and_validate_params
          if params_valid?
            setup_context
            chef_runner.converge
          else
            errors.each {|error| err("Error: #{error}") }
            parse_options
            msg(opt_parser)
            1
          end
        end

        def setup_context
          super
          generator_context.cookbook_root = cookbook_root
          generator_context.cookbook_name = cookbook_name
          generator_context.new_file_basename = new_file_basename
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
          unless File.directory?(File.join(cookbook_path, "recipes"))
            @errors << "Directory #{cookbook_path} is not a cookbook"
            @params_valid = false
          end
        end

        def params_valid?
          @params_valid
        end
      end

      # chef generate recipe [path/to/cookbook/root] name
      class Recipe < CookbookCodeFile

        banner "Usage: chef generate recipe [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          'recipe'
        end

      end

      # chef generate attribute [path/to/cookbook_root] NAME
      class Attribute < CookbookCodeFile

        banner "Usage: chef generate attribute [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          'attribute'
        end

      end

      # chef generate lwrp [path/to/cookbook_root] NAME
      class LWRP < CookbookCodeFile

        banner "Usage: chef generate lwrp [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          'lwrp'
        end

      end

      # chef generate template [path/to/cookbook_root] name --source=source_file
      class Template < CookbookCodeFile

        option :source,
          :short => "-s SOURCE_FILE",
          :long  => "--source SOURCE_FILE",
          :description => "Copy content from SOURCE_FILE"

        banner "Usage: chef generate template [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          'template'
        end

        def setup_context
          super
          generator_context.content_source = config[:source]
        end

      end

      # chef generate file [path/to/cookbook_root] name --source=source_file
      class CookbookFile < CookbookCodeFile
        option :source,
          :short => "-s SOURCE_FILE",
          :long  => "--source SOURCE_FILE",
          :description => "Copy content from SOURCE_FILE"

        banner "Usage: chef generate file [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          'cookbook_file'
        end

        def setup_context
          super
          generator_context.content_source = config[:source]
        end
      end

    end


  end
end

