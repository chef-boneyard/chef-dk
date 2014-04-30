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
require 'chef-dk/version'
require 'chef-dk/commands_map'
require 'chef-dk/builtin_commands'
require 'chef-dk/helpers'

module ChefDK
  class CLI
    include Mixlib::CLI
    include ChefDK::Helpers

    banner(<<-BANNER)
Usage:
    chef -h/--help
    chef -v/--version
    chef command [arguments...] [options...]
BANNER

    option :version,
      :short        => "-v",
      :long         => "--version",
      :description  => "Show chef version",
      :boolean      => true

    option :help,
      :short        => "-h",
      :long         => "--help",
      :description  => "Show this message",
      :boolean      => true

    attr_reader :argv

    def initialize(argv)
      @argv = argv
      super() # mixlib-cli #initialize doesn't allow arguments
    end

    def run
      subcommand_name, *subcommand_params = argv

      #
      # Runs the appropriate subcommand if the given parameters contain any
      # subcommands.
      #
      if subcommand_name.nil? || option?(subcommand_name)
        handle_options
      elsif have_command?(subcommand_name)
        subcommand = instantiate_subcommand(subcommand_name)
        exit_code = subcommand.run_with_default_options(subcommand_params)
        exit normalized_exit_code(exit_code)
      else
        err "Unknown command `#{subcommand_name}'."
        show_help
        exit 1
      end
    end

    # If no subcommand is given, then this class is handling the CLI request.
    def handle_options
      parse_options(argv)
      if config[:version]
        msg("Chef Development Kit Version: #{ChefDK::VERSION}")
      else
        show_help
      end
      exit 0
    end

    def show_help
      msg(banner)
      msg("\nAvailable Commands:")

      justify_length = subcommands.map(&:length).max + 2
      subcommand_specs.each do |name, spec|
        msg("    #{"#{name}".ljust(justify_length)}#{spec.description}")
      end
    end

    def exit(n)
      Kernel.exit(n)
    end

    def commands_map
      ChefDK.commands_map
    end

    def have_command?(name)
      commands_map.have_command?(name)
    end

    def subcommands
      commands_map.command_names
    end

    def subcommand_specs
      commands_map.command_specs
    end

    def option?(param)
      param =~ /^-/
    end

    def instantiate_subcommand(name)
      commands_map.instantiate(name)
    end

    private

    def normalized_exit_code(maybe_integer)
      if maybe_integer.kind_of?(Integer) and (0..255).include?(maybe_integer)
        maybe_integer
      else
        0
      end
    end

  end
end
