#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

# This is a windows only dependency

name "chef-dk-powershell-scripts"

license :project_license

# chef-dk-gems must be installed so we can get the chef gem's powershell scripts
dependency "chef-dk"

require_relative "../../files/chef-dk-gem/build-chef-dk-gem"

build do
  extend BuildChefDKGem
  block "Install windows powershell scripts" do
    # Copy the chef gem's distro stuff over
    chef_gem_path = shellout!("#{bundle_bin} show chef", env: env.merge("BUNDLE_GEMFILE" => shared_gemfile)).stdout.chomp
    chef_module_dir = File.join(install_dir, "modules", "chef")
    FileUtils.mkdir_p(chef_module_dir) if !File.exists?(chef_module_dir)
    Dir.glob("#{chef_gem_path}/distro/powershell/chef/*").each do |file|
      copy_file(file, chef_module_dir)
    end
  end
end
