#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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
      # chef generate file [path/to/cookbook_root] name --source=source_file
      class CookbookFile < CookbookCodeFile
        option :source,
          short: "-s SOURCE_FILE",
          long: "--source SOURCE_FILE",
          description: "Copy content from SOURCE_FILE"

        banner "Usage: chef generate file [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          "cookbook_file"
        end

        def setup_context
          super
          Generator.add_attr_to_context(:content_source, config[:source])
        end
      end
    end
  end
end
