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
    class Exec < ChefDK::Command::Base
      banner "Usage: chef exec SYSTEM_COMMAND"

      def run(params)
        user_bin_dir = File.expand_path(File.join(Gem.user_dir, 'bin'))
        env = {
          'PATH' => "#{user_bin_dir}:#{omnibus_embedded_bin_dir}:#{ENV['PATH']}",
          'GEM_ROOT' => Gem.default_dir.inspect,
          'GEM_HOME' => Gem.paths.home,
          'GEM_PATH' => Gem.path.join(':'),
        }
        exec env, *params
        raise "Exec failed without an exception, your ruby is buggy"  # should never get here
      end
    end
  end
end

