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

      SUPPORTED_SHELLS = %w[ bash fish zsh sh powershell posh].map(&:freeze).freeze

      banner(<<-HELP)
Usage: chef shell-init

`chef shell-init` modifies your shell environment to make ChefDK your default
ruby.

  To enable for just the current shell session:

    In sh, bash, and zsh:
      eval "$(chef shell-init SHELL_NAME)"
    In fish:
      eval (chef shell-init fish)
    In Powershell:
      chef shell-init powershell | Invoke-Expression

  To permanently enable:

    In sh, bash, and zsh:
      echo 'eval "$(chef shell-init SHELL_NAME)"' >> ~/.YOUR_SHELL_RC_FILE
    In fish:
      echo 'eval (chef shell-init SHELL_NAME)' >> ~/.config/fish/config.fish
    In Powershell
      "chef shell-init powershell | Invoke-Expression" >> $PROFILE

  If your shell specifies the SHELL environment variable, you may omit SHELL_NAME.

OPTIONS:

HELP

      option :omnibus_dir,
        :long         => "--omnibus-dir OMNIBUS_DIR",
        :description  => "Alternate path to omnibus install (used for testing)"

      def omnibus_root
        config[:omnibus_dir] || super
      end

      def run(argv)
        # Currently we don't have any shell-specific features, so we ignore the
        # shell name. We'll need it if we add completion.
        remaining_args = parse_options(argv)
        shell_name = File.basename(remaining_args.first || ENV['SHELL'] || '')
        if shell_name.empty?
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
        export(shell_name, "PATH", path)
        env.each do |var_name, value|
          export(shell_name, var_name, value)
        end
        0
      end

      def export(shell, var, val)
        case shell
        when 'sh', 'bash', 'zsh'
          posix_shell_export(var, val)
        when 'fish'
          fish_shell_export(var, val)
        when 'powershell', 'posh'
          powershell_export(var, val)
        end
      end

      def posix_shell_export(var, val)
        msg(%Q(export #{var}="#{val}"))
      end

      def fish_shell_export(var, val)
        # Fish's syntax for setting PATH is special. Path elements are
        # divided by spaces (instead of colons). We also send STDERR to
        # /dev/null to avoid Fish's helpful warnings about nonexistent
        # PATH elements.
        if var == 'PATH'
          msg(%Q(set -gx #{var} "#{val.split(':').join('" "')}" 2>/dev/null;))
        else
          msg(%Q(set -gx #{var} "#{val}";))
        end
      end

      def powershell_export(var, val)
        msg(%Q($env:#{var}="#{val}"))
      end
    end
  end
end


