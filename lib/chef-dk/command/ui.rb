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
  module Command

    class UI

      class NullStream

        def puts(*anything)
          nil
        end

      end

      def self.null
        new(out: NullStream.new, err: NullStream.new)
      end

      def initialize(out: nil, err: nil)
        @out = out || $stdout
        @err = err || $stderr
      end

      def err(message)
        @err.puts(message)
      end

      def msg(message)
        @out.puts(message)
      end
    end
  end
end

