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
require 'chef-dk/helpers'
require 'chef-dk/version'

module ChefDK
  module Command
    class Base
      include Mixlib::CLI
      include ChefDK::Helpers

      option :help,
        :short        => "-h",
        :long         => "--help",
        :description  => "Show this message",
        :boolean      => true

      option :version,
        :short        => "-v",
        :long         => "--version",
        :description  => "Show chef version",
        :boolean      => true

      def initialize
        super
      end

      #
      # optparser overwrites -h / --help options with its own.
      # In order to control this behavior, make sure the default options are
      # handled here.
      #
      def run_with_default_options(params = [ ])
        if needs_help?(params)
          msg(opt_parser.to_s)
          0
        elsif needs_version?(params)
          msg("Chef Development Kit Version: #{ChefDK::VERSION}")
          0
        else
          run(params)
        end
      end

      def needs_help?(params)
        params.include?("-h") || params.include?("--help")
      end

      def needs_version?(params)
        params.include?("-v") || params.include?("--version")
      end

    end
  end
end
