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

require "chef-dk/command/generator_commands/cookbook_code_file"

module ChefDK
  module Command
    module GeneratorCommands
      # chef generate resource [path/to/cookbook_root] NAME
      class Resource < CookbookCodeFile

        banner "Usage: chef generate resource [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          "resource"
        end
      end
    end
  end
end
