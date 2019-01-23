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

require "fileutils"

require "chef-dk/configurable"
require "chef-dk/ui"
require "chef-dk/command/generator_commands/base"

module ChefDK
  module Command
    module GeneratorCommands

      # chef generate generator [NAME]
      # --
      # There is already a `Generator` class a few levels up that other classes
      # are referring to via relative constant, so name this
      # `GeneratorGenerator` to avoid causing a conflict.
      class GeneratorGenerator < Base

        banner "Usage: chef generate generator [ PATH ] [options]"

        attr_reader :destination_dir
        attr_accessor :ui

        def initialize(*args)
          super
          @destination_dir = nil
          @ui = UI.new
          @custom_cookbook_name = false
        end

        def run
          return 1 unless verify_params!
          FileUtils.cp_r(source, destination_dir)
          update_metadata_rb
          ui.msg("Copied built-in generator cookbook to #{created_cookbook_path}")
          ui.msg("Add the following to your config file to enable it:")
          ui.msg("  chefdk.generator_cookbook \"#{created_cookbook_path}\"")
          0
        end

        # @api private
        def cookbook_name
          if custom_cookbook_name?
            File.basename(destination_dir)
          else
            "code_generator"
          end
        end

        # @api private
        def verify_params!
          case params.size
          when 0
            @destination_dir = Dir.pwd
            true
          when 1
            set_destination_dir_from_args(params.first)
          else
            ui.err("ERROR: Too many arguments.")
            ui.err(opt_parser)
            false
          end
        end

        # @api private
        def source
          # Hard-coded to the built-in generator, because otherwise setting
          # chefdk.generator_cookbook would make this command copy the custom
          # generator, but that doesn't make sense because the user can easily
          # do that anyway.
          File.expand_path("../../../skeletons/code_generator", __FILE__)
        end

        private

        # @api private
        def update_metadata_rb
          File.open(File.join(created_cookbook_path, "metadata.rb"), "w+") do |f|
            f.print(metadata_rb)
          end
        end

        def created_cookbook_path
          if custom_cookbook_name?
            destination_dir
          else
            File.join(destination_dir, "code_generator")
          end
        end

        # @api private
        def metadata_rb
          <<~METADATA
            name             '#{cookbook_name}'
            description      'Custom code generator cookbook for use with ChefDK'
            long_description 'Custom code generator cookbook for use with ChefDK'
            version          '0.1.0'

          METADATA
        end

        def custom_cookbook_name?
          @custom_cookbook_name
        end

        def set_destination_dir_from_args(given_path)
          path = File.expand_path(given_path)
          if check_for_conflicting_dir(path) ||
              check_for_conflicting_file(path) ||
              check_for_missing_parent_dir(path)
            false
          else
            @destination_dir = File.expand_path(path)
            @custom_cookbook_name = !File.exist?(destination_dir)
            true
          end
        end

        def conflicting_file_exists?(path)
          File.exist?(path) && File.file?(path)
        end

        def check_for_conflicting_dir(path)
          conflicting_subdir_path = File.join(path, "code_generator")
          if File.exist?(path) &&
              File.directory?(path) &&
              File.exist?(conflicting_subdir_path)
            ui.err("ERROR: file or directory #{conflicting_subdir_path} exists.")
            true
          else
            false
          end
        end

        def check_for_conflicting_file(path)
          if File.exist?(path) && !File.directory?(path)
            ui.err("ERROR: #{path} exists and is not a directory.")
            true
          else
            false
          end
        end

        def check_for_missing_parent_dir(path)
          parent = File.dirname(path)
          if !File.exist?(parent)
            ui.err("ERROR: enclosing directory #{parent} does not exist.")
            true
          else
            false
          end
        end

      end

    end
  end
end
