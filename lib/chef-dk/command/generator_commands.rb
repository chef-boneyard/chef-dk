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
require 'chef/config_fetcher'

module ChefDK
  module Command

    # ## SharedGeneratorOptions
    #
    # These CLI options are shared amongst the generator commands
    module SharedGeneratorOptions
      include Mixlib::CLI

      # You really want these to have default values, as
      # they will likely be used all over the place.
      option :license,
        :short => "-I LICENSE",
        :long => "--license LICENSE",
        :description => "all_rights, apache2, mit, gplv2, gplv3 - defaults to all_rights",
        :default => "all_rights"

      option :copyright_holder,
        :short => "-C COPYRIGHT",
        :long => "--copyright COPYRIGHT",
        :description => "Name of the copyright holder - defaults to 'The Authors'",
        :default => "The Authors"

      option :email,
        :short => "-m EMAIL",
        :long => "--email EMAIL",
        :description => "Email address of the author - defaults to 'you@example.com'",
        :default => 'you@example.com'

      option :json_attribs,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes JSON_ATTRIBS",
        :description => "Load attributes from a JSON file or URL",
        :default => nil,
        :proc => Proc.new { |s| Chef::ConfigFetcher.new(File.expand_path(s)).fetch_json }

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
