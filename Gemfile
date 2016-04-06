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

# path is needed because when we attempt to load this gemspec to look at it from
# another bundle, it will expand the path relative to the other bundle rather than
# this file.
gemspec path: File.dirname(__FILE__), name: "chef-dk"

# EXPERIMENTAL: ALL gems specified here will be installed in chef-dk omnibus.
# This represents all gems that will be part of chef-dk.

# All software we recognize needs to stay at the latest possible version. But
# since that's not expressible here, we make it >= the last *known* version to
# at least prevent downgrades beyond that:
gem "appbundler", github: "chef/appbundler" # until next release with multiple-gem support
gem "berkshelf"
# Chef 12.8.1 Gem includes some extra files which can break gem installation on
# windows. For now we are pulling chef from github at the tag as a workaround.
gem "chef-provisioning", ">= 1.6.0", github: "chef/chef-provisioning" # until chef-provisioning with mixlib-install 1.0 is released
gem "chef-provisioning-aws", ">= 1.8.0"
gem "chef-provisioning-azure", ">= 0.5.0"
gem "chef-provisioning-fog", ">= 0.18.0"
gem "chef-provisioning-vagrant", ">= 0.11.0"
gem "chef-vault", github: "chef/chef-vault" # Until a version is released with a Gemfile
gem "chef", github: "chef/chef", branch: "v12.9.7"
gem "cheffish", ">= 2.0.3"
gem "chefspec"
gem "fauxhai"
gem "foodcritic", github: "acrmp/foodcritic" # Until a version is released with a Gemfile
gem "inspec", ">= 0.17.1"
gem "kitchen-ec2"
gem "kitchen-inspec"
gem "kitchen-vagrant"
gem "knife-windows"
gem "ohai", ">= 8.13.0"
gem "test-kitchen", ">= 1.6.0"

# All of the following used to be software definitions we included:
gem "knife-spork"
gem "dep-selector-libgecode"
gem "nokogiri"
gem "pry"
gem "pry-byebug"
gem "pry-remote"
gem "pry-stack_explorer"
gem "rb-readline"
gem "rubocop", "~> 0.37.2"
gem "winrm-fs"
# `json_pure` has a bug in it that is failing ChefDK builds.  We include the
# prevents loading the `json_pure` gem
gem 'json', '>= 1.8.1'
# NOTE this needs to be excluded from AIX too, but we don't support that on
# ChefDK and putting a thing in multiple groups :no_windows, :no_aix won't work
# because it --without no_aix will still install things in group :no_windows.
# Need to specify groups positively; investigate.
# http://stackoverflow.com/questions/8420414/how-to-add-mac-specific-gems-to-bundle-on-mac-but-not-on-linux
group :no_windows do
  gem "ruby-shadow"
end

# bundled or development dependencies we want to ship
gem "dep_selector"
gem "guard"
gem "ruby-prof"
gem "rake"
gem "rdoc"
gem "yard"
