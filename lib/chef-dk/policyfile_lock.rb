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

require 'chef-dk/cookbook_profiler/identifiers'

module ChefDK
  class PolicyfileLock

    class CachedCookbook

      attr_accessor :cache_key
      attr_reader :cache_path

      def initialize(name, cache_path)
        @name = name
        @cache_path = cache_path
      end

      def cookbook_path
        File.join(cache_path, cache_key)
      end

      def to_lock
        identifiers = CookbookProfiler::Identifiers.new(cookbook_path)

        {
          "version" => identifiers.semver_version,
          "identifier" => identifiers.content_identifier,
          "dotted_decimal_identifier" => identifiers.dotted_decimal_identifier,
          "cache_key" => cache_key
        }
      end

    end

    NULL = Object.new.freeze

    def self.build(options = {})
      lock = new(options)
      yield lock
      lock
    end

    attr_accessor :name
    attr_accessor :run_list
    attr_reader :cookbook_locks
    attr_reader :cache_path

    def initialize(options = {})
      @name = nil
      @run_list = []
      @cookbook_locks = {}
      handle_options(options)
    end

    def cached_cookbook(name)
      cached_cookbook = CachedCookbook.new(name, cache_path)
      yield cached_cookbook
      @cookbook_locks[name] = cached_cookbook
    end

    def to_lock
      {}.tap do |lock|
        lock["name"] = name
        lock["run_list"] = run_list
        lock["cookbook_locks"] = cookbook_locks_for_lockfile
      end
    end

    def cookbook_locks_for_lockfile
      cookbook_locks.inject({}) do |locks_map, (name, cookbook_spec)|
        locks_map[name] = cookbook_spec.to_lock
        locks_map
      end
    end

    private

    def handle_options(options)
      @cache_path = options[:cache_path]
    end
  end
end
