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

require "chef-dk/command/base"
require "chef-dk/cookbook_omnifetch"
require "chef-dk/ui"
require "chef-dk/version"
require "mixlib/shellout"
require "yaml"

module ChefDK
  module Command
    class Env < ChefDK::Command::Base
      banner "Usage: chef env"

      attr_accessor :ui

      def initialize(*args)
        super
        @ui = UI.new
      end

      def run(params)
        info = {}
        info["Chef Development Kit"] = Hash.new.tap do |chefdk_env|
          chefdk_env["ChefDK"] = chefdk_info
          chefdk_env["Ruby"] = ruby_info
          chefdk_env["Path"] = paths
        end
        ui.msg info.to_yaml
      end

      def chefdk_info
        Hash.new.tap do |chefdk|
          chefdk["ChefDK Version"] = ChefDK::VERSION
          chefdk["ChefDK Home"] = chefdk_home
          chefdk["ChefDK Install Directory"] = omnibus_root
          chefdk["Policyfile Config"] = policyfile_config
        end
      end

      def ruby_info
        Hash.new.tap do |ruby|
          ruby["Ruby Executable"] = Gem.ruby
          ruby["Ruby Version"] = RUBY_VERSION
          ruby["RubyGems"] = Hash.new.tap do |rubygems|
            rubygems["RubyGems Version"] = Gem::VERSION
            rubygems["RubyGems Platforms"] = Gem.platforms.map(&:to_s)
            rubygems["Gem Environment"] = gem_environment
          end
        end
      end

      def gem_environment
        Hash.new.tap do |h|
          h["GEM ROOT"] = omnibus_env["GEM_ROOT"]
          h["GEM HOME"] = omnibus_env["GEM_HOME"]
          h["GEM PATHS"] = omnibus_env["GEM_PATH"].split(File::PATH_SEPARATOR)
        end
      end

      def paths
        omnibus_env["PATH"].split(File::PATH_SEPARATOR)
      end

      def policyfile_config
        Hash.new.tap do |h|
          h["Cache Path"] = CookbookOmnifetch.cache_path
          h["Storage Path"] = CookbookOmnifetch.storage_path.to_s
        end
      end

    end
  end
end
