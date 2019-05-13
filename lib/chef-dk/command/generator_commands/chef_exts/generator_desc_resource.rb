#
# Copyright:: Copyright (c) 2016-2019 Chef Software Inc.
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

require "chef/resource"

module ChefDK
  module ChefResource

    # GeneratorDesc is similar to Chef's built-in log resource, but instead of
    # sending output through the logger, it sends output through the output
    # formatter, which avoids the extra formatting that the logger would add.
    #
    # As the name implies, it is used to describe the steps that the generator
    # takes to create a cookbook.
    class GeneratorDesc < Chef::Resource
      resource_name :generator_desc

      property :message, String, name_property: true

      # Write the log to Chef's log
      action :write do
        run_context.events.subscribers.first.puts_line("- #{new_resource.message}")
      end
    end
  end
end
