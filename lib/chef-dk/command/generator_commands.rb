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
    end
  end
end
