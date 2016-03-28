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

source 'https://rubygems.org'

gemspec :name => "chef-dk"

# EXPERIMENTAL: ALL gems specified here will be installed in chef-dk omnibus.
# This represents all gems that will be part of chef-dk.

# All of the following used to be software definitions we included:
gem "appbundler", github: "chef/appbundler", branch: "jk/multiple-gems"
gem "berkshelf"
# Chef 12.8.1 Gem includes some extra files which can break gem installation on
# windows. For now we are pulling chef from github at the tag as a workaround.
gem "chef", github: "chef/chef", branch: "v12.9.7"
gem "chef-provisioning"
gem "chef-provisioning-aws"
gem "chef-provisioning-azure"
gem "chef-provisioning-fog"
gem "chef-provisioning-vagrant"
gem "chef-vault"
gem "chefspec"
gem "dep-selector-libgecode"
gem "fauxhai"
gem "foodcritic"
gem "inspec"
gem "kitchen-ec2"
gem "kitchen-inspec"
gem "kitchen-vagrant"
gem "knife-windows"
gem "knife-spork"
gem "nokogiri"
gem "ohai"
gem "pry"
gem "pry-byebug"
gem "pry-remote"
gem "pry-stack_explorer"
gem "rb-readline"
gem "rubocop", "~> 0.37.2"
gem "test-kitchen"
gem "winrm-fs"

# bundled or development dependencies we want to ship
gem "dep_selector"
gem "guard"
gem "ruby-prof"
gem "rake"
gem "rdoc"
gem "yard"
