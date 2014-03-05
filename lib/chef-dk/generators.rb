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

require 'erubis'

module ChefDK

  module Generators

    class TemplateContext < Erubis::Context
    end

    class FileGenerator

      def initialize(source_template, destination)
        @source_template = source_template
        @destination = destination
      end

    end

    class Tree

      attr_reader :source_skeleton
      attr_reader :destination
      attr_reader :example_code

      def initialize(source_skeleton, destination, example_code: false)
        @source_skeleton = source_skeleton
        @destination = destination
        @example_code = example_code
      end

      def run
        # for each skeleton file:
        # derive the target path.
        # create a Generator::File object and run it.
        #
        # Figure out: 
        # * will Generator::File take care of mkdir-ing the directories, or
        # should we do this in one go?
        # * what's the API for defining the template's variables?
        # * how does the example code get rendered?
        #
      end

      def skeleton_files
        @skeleton_files ||= skeleton_fs_entries.select { |entry| File.file?(entry) }
      end

      def skeleton_fs_entries
        @skeleton_fs_entries ||= Dir.glob("#{source_skeleton}/**/*", File::FNM_DOTMATCH)
      end

    end
  end
end
