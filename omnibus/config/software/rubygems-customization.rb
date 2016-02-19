#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

name "rubygems-customization"

source path: "#{project.files_path}/#{name}"

dependency "rubygems"

build do
  block "Add Rubygems customization file" do
    source_customization_file = if windows?
      "#{project_dir}/windows/operating_system.rb"
    else
      "#{project_dir}/default/operating_system.rb"
    end

    source_content = File.read(source_customization_file)

    # Patch both the system rubygems and the upgraded "site" rubygems.
    ["sitelibdir", "rubylibdir"].each do |config|
      path = Bundler.with_clean_env do
        ruby = windows_safe_path("#{install_dir}/embedded/bin/ruby")
        %x|#{ruby} -rrbconfig -e "puts RbConfig::CONFIG['#{config}']"|.strip
      end
      if path.nil? || path.empty?
        raise "Could not determine embedded Ruby's #{config} directory, aborting!"
      end

      destination = "#{path}/rubygems/defaults/operating_system.rb"
      FileUtils.mkdir_p(File.dirname(destination))
      # Don't assume that we're the only ones with rubygems customization.
      # Put our stuff before any existing customization.
      if File.exist?(destination)
        File.open(destination, "r+") do |f|
          unpatched_customization = f.read
          f.rewind
          f.write(source_content)
          f.write(unpatched_customization)
        end
      else
        FileUtils.cp source_customization_file, destination
      end
    end
  end
end
