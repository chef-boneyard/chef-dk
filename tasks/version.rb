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

namespace :version do
  task :bump => [ 'version:bump_patch', 'dependencies:update_conservative' ]

  task :show do
    puts ChefDK::VERSION
  end

  def version_rb_path
    File.expand_path("../../lib/chef-dk/version.rb", __FILE__)
  end

  # Add 1 to the current patch version in the VERSION file, and write it back out.
  task :bump_patch do
    current_version_file = IO.read(version_rb_path)
    new_version = nil
    new_version_file = current_version_file.sub(/^(\s*VERSION\s*=\s*")(\d+\.\d+\.)(\d+)/) do
      new_version = "#{$2}#{$3.to_i + 1}"
      "#{$1}#{new_version}"
    end
    puts "Updating version in #{version_rb_path} from #{ChefDK::VERSION} to #{new_version.chomp}"
    IO.write(version_rb_path, new_version_file)
  end

end
