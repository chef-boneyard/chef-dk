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

require "mixlib/shellout"

module ChefDK

  # A subclass of Mixlib::ShellOut that conforms to the API expected by
  # CookbookOmnifetch
  class ShellOut < Mixlib::ShellOut
    def self.shell_out(*command_args)
      cmd = new(*command_args)
      cmd.run_command
      cmd
    end

    def success?
      !error?
    end
  end

end
