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

require 'chef/cookbook/metadata'
require 'chef-dk/exceptions'

module ChefDK
  class CookbookCacheManager

    attr_reader :policyfile
    attr_reader :relative_root
    attr_reader :cache_path

    def initialize(policyfile, config={})
      @policyfile = policyfile
      @relative_root = config[:relative_root] || Dir.pwd
      @cache_path = config[:cache_path]
      @local_cookbooks_metadata = {}
    end

    def cookbook_version(cookbook_name)
      metadata_for(cookbook_name).version
    end

    private

    def metadata_for(cookbook_name)
      if cached_metadata = @local_cookbooks_metadata[cookbook_name]
        return cached_metadata
      else
        metadata = load_metadata_for(cookbook_name)
        @local_cookbooks_metadata[cookbook_name] = metadata
        metadata
      end
    end

    def load_metadata_for(cookbook_name)
      local_cookbook_path = path_to_local_cookbook(cookbook_name)
      metadata_rb_path = File.join(local_cookbook_path, "metadata.rb")
      if !File.exist?(local_cookbook_path)
        raise LocalCookbookNotFound, "Cookbook `#{cookbook_name}' not found in the expected location (#{local_cookbook_path})"
      elsif !File.exist?(metadata_rb_path)
        raise MalformedCookbook, "Cookbook `#{cookbook_name}' does not contain a metadata.rb file (expected to find it at path #{metadata_rb_path})"
      end
      Chef::Cookbook::Metadata.new.tap { |m| m.from_file(metadata_rb_path) }
    end

    def path_to_local_cookbook(cookbook_name)
      relative_path = policyfile.cookbook_source_overrides[cookbook_name][:path]
      File.expand_path(relative_path, relative_root)
    end

  end
end
