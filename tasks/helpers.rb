#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

# Putting this method in a module so it is easier to test
module RakeDependenciesTaskHelpers
  def update_gemfile_from_stable(gemfile, product_name, gemfile_name, version_prefix = "")
    version = get_latest_version_for(product_name)
    version = "#{version_prefix}#{version}"
    found = gemfile.sub!(/^(\s*gem "#{gemfile_name}", github: "chef\/#{gemfile_name}", branch: ")([^"]*)(")$/m) do
      if $2 != "#{version}"
        puts "Setting #{product_name} version in Gemfile to #{version} (was #{$2})"
      else
        puts "#{product_name} version in Gemfile already at latest stable (#{$2})"
      end
      "#{$1}#{version}#{$3}"
    end
    unless found
      raise "Gemfile does not have a line of the form 'gem \"#{gemfile_name}\", github: \"chef/#{gemfile_name}\", branch: \"<version>\"', so we didn't update it to latest stable (#{version})."
    end
    gemfile
  end

  def get_latest_version_for(product_name, channel_name = :stable)
    require "mixlib/install"
    puts "Getting latest '#{channel_name}' channel #{product_name} version ..."
    options = {
      channel: channel_name.to_sym,
      product_version: :latest,
      product_name: product_name,
    }
    Mixlib::Install.new(options).artifact_info.first.version
  end
end
