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

require 'chef-dk/command/base'
require 'chef-dk/command/generator_commands'

module ChefDK
  module Command
    class Generate < Base

      GeneratorCommand = Struct.new(:name, :class_name, :description)

      def self.generators
        @generators ||= []
      end

      def self.generator(name, class_name, description)
        generators << GeneratorCommand.new(name, class_name, description)
      end

      generator(:app, :App, "Generate an application repo")
      generator(:cookbook, :Cookbook, "Generate a single cookbook")
      generator(:recipe, :Recipe, "Generate a new recipe")
      generator(:attribute, :Attribute, "Generate an attributes file")
      generator(:template, :Template, "Generate a file template")
      generator(:file, :CookbookFile, "Generate a cookbook file")
      generator(:lwrp, :LWRP, "Generate a lightweight resource/provider")

      def self.banner_headline
        <<-E
Usage: chef generate GENERATOR [options]

Available generators:
E
      end

      def self.generator_list
        justify_size = generators.map {|g| g.name.size }.max + 2
        generators.map {|g| "  #{g.name.to_s.ljust(justify_size)}#{g.description}"}.join("\n")
      end

      def self.banner
        banner_headline + generator_list + "\n"
      end

      # chef generate app path/to/basename --skel=path/to/skeleton --example
      # chef generate file name [path/to/cookbook_root] (inferred from cwd) --from=source_file

      def initialize(*args)
        super
      end

      def run(params)
        if generator_spec = generator_for(params[0])
          params.shift
          generator = GeneratorCommands.build(generator_spec.class_name, params)
          generator.run
        else
          msg(banner)
          1
        end
      end

      def generator_for(arg)
        self.class.generators.find {|g| g.name.to_s == arg}
      end

      # In the Base class, this is defined to be true if any args match "-h" or
      # "--help". Here we override that behavior such that if the first
      # argument is a valid generator name, like `chef generate cookbook -h`,
      # we delegate the request to the specified generator.
      def needs_help?(params)
        return false if have_generator?(params[0])
        super
      end

      def have_generator?(name)
        self.class.generators.map {|g| g.name.to_s}.include?(name)
      end

    end
  end
end
