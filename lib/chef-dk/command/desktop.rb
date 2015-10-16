#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require 'chef-dk/ui'
require 'chef-dk/version'
require 'chef-dk/chef_runner'

module ChefDK
  module Command
    class Desktop < ChefDK::Command::Base
      banner(<<-BANNER)
Usage: chef desktop [--path CONFIG_DIR ]

`chef desktop` Assits in setting up the local workstation.

Options:
BANNER

      option :cookbooks_path,
        :long         => "--cookbooks-path COOKBOOKS-PATH",
        :description  => "Alternate directory to find Chef Desktop cookbooks"

      option :cookbook,
        :long         => "--cookbook COOKBOOK",
        :description  => "Alternate cookbook to execute, defaults to 'desktop'"

      attr_accessor :ui

      def initialize(*args)
        super
        @desktop_cookbooks_path = nil
        @desktop_cookbook_name = nil
        @desktop_recipe = nil
        @ui = UI.new
      end

      def chef_runner(run_list)
        @chef_runner ||= ChefRunner.new(cookbooks_path, run_list)
      end

      def run_list(recipes)
        ["recipe[#{desktop_cookbook_name}]"] unless recipes
        recipes.map {|recipe| ["recipe[#{desktop_cookbook_name}::#{recipe}]"] }
      end

      def cookbooks_path
        config[:cookbooks_path] || File.join(chefdk_home, 'desktop', 'cookbooks')
      end

      def desktop_cookbook_name
        config[:cookbook] || 'desktop'
      end

      def desktop_recipe
        config[:recipe] || 'default'
      end

      def apply_params!(params)
        remaining_args = parse_options(params)
      end

      def run(params = [])
        return 1 unless apply_params!(params)
        run_list = run_list(params)
        chef_runner(run_list).converge
        0
      end

    end
  end
end
