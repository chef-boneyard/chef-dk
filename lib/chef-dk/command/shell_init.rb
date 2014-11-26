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
require 'mixlib/shellout'

module ChefDK
  module Command
    class ShellInit < ChefDK::Command::Base

      SUPPORTED_SHELLS = %w[ bash zsh sh powershell posh cmd ].map(&:freeze).freeze

      banner(<<-HELP)
Usage: chef shell-init

`chef shell-init` modifies your shell environment to make ChefDK your default
ruby.

  To enable for just the current shell session:

  For sh, zsh, and bash:
    eval "$(chef shell-init SHELL_NAME)"
  For powershell:
    chef shell-init powershell | Invoke-Expression

  To permanently enable:

  For sh, zsh, and bash:
    echo 'eval "$(chef shell-init SHELL_NAME)"' >> ~/.YOUR_SHELL_RC_FILE
  For powershell:
    "chef shell-init powershell | Invoke-Expression" >> $PROFILE

Supported shells: #{SUPPORTED_SHELLS.join(' ')}

OPTIONS:

HELP

      option :omnibus_dir,
        :long         => "--omnibus-dir OMNIBUS_DIR",
        :description  => "Alternate path to omnibus install (used for testing)"

      def omnibus_root
        config[:omnibus_dir] || super
      end

      # some of these environment variables have quotes around them as written
      # if that is not the case, add them for powershell set-item invocation
      def singlequote(value)
          quotechars = %w[ ' " ]
          if (!quotechars.include?(value[0]))
            return "'#{value}'"
          end
          value
      end

      # Powershell symbol export
      # note that this requires the fix for #180
      # https://github.com/opscode/chef-dk/issues/180
      def powershell(name, value)
        value = singlequote value
        msg("Set-Item Env:\\#{name} #{value}")
      end
      alias :posh :powershell

      # Windows cmd symbol export
      # note that this requires the fix for #180
      # https://github.com/opscode/chef-dk/issues/180
      def cmd(name, value)
        msg("SET #{name}=#{value}")
      end

      def sh(name, value)
        msg("export #{name}=#{value}")
      end
      alias :bash :sh
      alias :zsh :sh

      def run(argv)
        remaining_args = parse_options(argv)
        shell_name = remaining_args.first
        if shell_name.nil?
          err("Please specify what shell you are using\n")
          err(opt_parser.to_s)
          return 1
        elsif !SUPPORTED_SHELLS.include?(shell_name)
          err("Shell `#{shell_name}' is not currently supported")
          err("Supported shells are: #{SUPPORTED_SHELLS.join(' ')}")
          return 1
        end

        env = omnibus_env.dup
        path = env.delete("PATH")
        self.send shell_name, "PATH", path
        env.each do |var_name, value|
          self.send shell_name, var_name, value
        end
        0
      end
    end
  end
end


