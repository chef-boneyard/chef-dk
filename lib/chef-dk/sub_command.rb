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

module ChefDK
  module SubCommand
    #
    # Methods to store sub_command definitions in class.
    #
    module ClassMethods
      def sub_command(command_name, command_class)
        @sub_commands ||= Hash.new
        @sub_commands[command_name] = command_class
      end

      attr_accessor :sub_commands
    end

    def sub_commands
      self.class.sub_commands
    end

    def sub_command?(param)
      !(param =~ /^-/)
    end

    #
    # Runs the appropriate sub_command if the given parameters contain any
    # sub_commands.
    #
    def run_sub_commands(params)
      if params && sub_command?(params[0]) && sub_commands[params[0]]
        command_class = sub_commands[params[0]].send(:new)
        params.shift
        command_class.run(params)
        true
      else
        false
      end
    end

    def self.included(base)
      base.extend(ChefDK::SubCommand::ClassMethods)
    end
  end
end
