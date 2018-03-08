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

require "chef-dk/command/base"
require "mixlib/shellout"

module ChefDK
  module Command
    class Exec < ChefDK::Command::Base
      banner "Usage: chef exec SYSTEM_COMMAND"

      def run(params)
        # Set ENV directly on the "parent" process (us) before running #exec to
        # ensure the custom PATH is honored when finding the command to exec
        omnibus_env.each { |var, value| ENV[var] = value }
        exec(*params)
        raise "Exec failed without an exception, your ruby is buggy" # should never get here
      end

      def needs_version?(params)
        # Force version to get passed down to command
        false
      end

      def needs_help?(params)
        ["-h", "--help"].include? params[0]
      end
    end
  end
end
