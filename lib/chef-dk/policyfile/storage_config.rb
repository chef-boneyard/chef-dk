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

require 'chef-dk/cookbook_omnifetch'

module ChefDK
  module Policyfile

    class StorageConfig

      attr_accessor :relative_paths_root
      attr_accessor :cache_path

      attr_reader :policyfile_filename
      attr_reader :policyfile_lock_filename

      def initialize(options = {})
        @relative_paths_root = Dir.pwd
        @cache_path = CookbookOmnifetch.storage_path
        @policyfile_filename = "<< Policyfile filename not specified >>"
        @policyfile_lock_filename = "<< Policyfile lock filename not specified >>"
        handle_options(options)
      end

      def use_policyfile(policyfile_filename)
        @policyfile_filename = policyfile_filename
        @relative_paths_root = File.dirname(policyfile_filename)
        self
      end

      def use_policyfile_lock(policyfile_lock_filename)
        @policyfile_lock_filename = policyfile_lock_filename
        @relative_paths_root = File.dirname(policyfile_lock_filename)
        self
      end

      private

      def handle_options(options)
        @cache_path = options[:cache_path] if options[:cache_path]
        @relative_paths_root = options[:relative_paths_root] if options.key?(:relative_paths_root)
      end
    end

    module StorageConfigDelegation

      def cache_path
        storage_config.cache_path
      end

      def relative_paths_root
        storage_config.relative_paths_root
      end

      def policyfile_filename
        storage_config.policyfile_filename
      end

    end

  end
end

