#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

  # CommandsMap maintains a mapping of subcommand names to the files where
  # those commands are defined and the classes that implement the commands.
  #
  # In ruby it's more typical to handle this sort of thing using conventions
  # and metaprogramming. We've implemented this approach in the past and
  # decided against it here:
  # 1. Performance. As the CLI suite grows, you have to load more and more
  # code, including dependencies that are installed by rubygems, etc. This gets
  # slow, and CLI apps need to be fast.
  # 2. You can workaround the above by having a convention mapping filename to
  # command name, but then you have to do a lot of work to list all of the
  # commands, which is actually a common thing to do.
  # 3. Other ways to mitigate the performance issue (loading deps lazily) have
  # their own complications and tradeoffs and don't fully solve the problem.
  # 4. It's not actually that much work to maintain the mapping.
  #
  # ## Adding new commands globally:
  #
  # A "singleton-ish" instance of this class is stored as ChefDK.commands_map.
  # You can configure a multiple commands at once in a block using
  # ChefDK.commands, like so:
  #
  #   ChefDK.commands do |c|
  #     # assigns `chef my-command` to the class ChefDK::Command::MyCommand.
  #     # The "require path" is inferred to be "chef-dk/command/my_command"
  #     c.builtin("my-command", :MyCommand)
  #
  #     # Set the require path explicitly:
  #     c.builtin("weird-command", :WeirdoClass, require_path: "chef-dk/command/this_is_cray")
  #
  #     # You can add a description that will show up in `chef -h` output (recommended):
  #     c.builtin("documented-cmd", :DocumentedCmd, desc: "A short description")
  #   end
  #
  class CommandsMap
    NULL_ARG = Object.new

    CommandSpec = Struct.new(:name, :constant_name, :require_path, :description, :hidden)

    class CommandSpec

      def instantiate
        require require_path
        command_class = ChefDK::Command.const_get(constant_name)
        command_class.new
      end

    end

    attr_reader :command_specs

    def initialize
      @command_specs = {}
    end

    def builtin(name, constant_name, require_path: NULL_ARG, desc: "", hidden: false)
      if null?(require_path)
        snake_case_path = name.tr("-", "_")
        require_path = "chef-dk/command/#{snake_case_path}"
      end
      command_specs[name] = CommandSpec.new(name, constant_name, require_path, desc, hidden)
    end

    def instantiate(name)
      spec_for(name).instantiate
    end

    def have_command?(name)
      command_specs.key?(name)
    end

    def command_names
      command_specs.keys
    end

    def spec_for(name)
      command_specs[name]
    end

    private

    def null?(argument)
      argument.equal?(NULL_ARG)
    end
  end

  def self.commands_map
    @commands_map ||= CommandsMap.new
  end

  def self.commands
    yield commands_map
  end
end
