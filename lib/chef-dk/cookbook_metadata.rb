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

require "chef-dk/exceptions"
require "chef/cookbook/metadata"

module ChefDK

  # Subclass of Chef's Cookbook::Metadata class that provides the API expected
  # by CookbookOmnifetch
  class CookbookMetadata < Chef::Cookbook::Metadata

    def self.from_path(path)
      metadata_json_path = File.join(path, "metadata.json")
      metadata_rb_path = File.join(path, "metadata.rb")

      if File.exist?(metadata_json_path)
        new.tap { |m| m.from_json(File.read(metadata_json_path)) }
      elsif File.exist?(metadata_rb_path)
        new.tap { |m| m.from_file(metadata_rb_path) }
      else
        raise MalformedCookbook, "Cookbook at #{path} has neither metadata.json or metadata.rb"
      end
    end

    def cookbook_name
      name
    end

  end
end
