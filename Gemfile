#
# Copyright:: Copyright (c) 2014-2016 Chef Software Inc.
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

source "https://rubygems.org"

# Note we do not use the gemspec DSL which restricts to the
# gemspec for the current platform and filters out other platforms
# during a bundle lock operation. We actually want dependencies from
# both of our gemspecs. Also note this this mimics gemspec behavior
# of bundler versions prior to 1.12.0 (https://github.com/bundler/bundler/commit/193a14fe5e0d56294c7b370a0e59f93b2c216eed)
gem "chef-dk", path: "."

# EXPERIMENTAL: ALL gems specified here will be installed in chef-dk omnibus.
# This represents all gems that will be part of chef-dk.

group(:omnibus_package, :development, :test) do
  gem "rake"
  gem "pry"
  gem "rdoc"
  gem "yard"
  gem "dep_selector"
  gem "guard"
  gem "ruby-prof"
  gem "cookstyle", ">= 1.3.0"
  gem "foodcritic", ">= 9.0"
  # This is here temporarily until we can get oc-chef-pedant fixed
  gem "veil", git: "https://github.com/chef/chef_secrets.git"
end

# All software we recognize needs to stay at the latest possible version. But
# since that's not expressible here, we make it >= the last *known* version to
# at least prevent downgrades beyond that:
group(:omnibus_package) do
  gem "appbundler", github: "chef/appbundler" # until next release with multiple-gem support
  gem "berkshelf", ">= 5.0"
  # Chef 12.8.1 Gem includes some extra files which can break gem installation on
  # windows. For now we are pulling chef from github at the tag as a workaround.
  gem "chef-provisioning", ">= 2.0"
  gem "chef-provisioning-aws", ">= 2.0"
  gem "chef-provisioning-azure", ">= 0.6.0"
  gem "chef-provisioning-fog", ">= 0.20.0"
  gem "chef-provisioning-vagrant", ">= 0.11.0"
  gem "chef-vault"
  # The chef version is pinned by "rake dependencies", which grabs the current version from omnibus.
  gem "chef", github: "chef/chef", branch: "v12.19.36"
  gem "cheffish", ">= 4.0"
  gem "chefspec"
  gem "fauxhai"
  gem "inspec", ">= 0.17.1"
  gem "kitchen-ec2"
  gem "kitchen-dokken", ">= 2.1.0"
  gem "kitchen-inspec"
  gem "kitchen-vagrant"
  gem "knife-windows"
  gem "knife-opc", ">= 0.3.2"
  gem "ohai", ">= 8.13.0"
  gem "test-kitchen"
  gem "listen"
  gem "dco"

  # For Delivery build node
  gem "chef-sugar"
  gem "mixlib-versioning"
  gem "artifactory"
  # The opscode-pushy-client version is pinned by "rake dependencies", which grabs the current version from omnibus.
  gem "opscode-pushy-client", github: "chef/opscode-pushy-client", branch: "2.1.2"
  gem "ffi-rzmq-core"
  gem "knife-push"

  # All of the following used to be software definitions we included:
  gem "knife-spork"
  gem "dep-selector-libgecode"
  # gem "nokogiri"
  gem "pry-byebug"
  gem "pry-remote"
  gem "pry-stack_explorer"
  gem "rb-readline"
  gem "rubocop"
  gem "winrm-fs"
  gem "winrm-elevated"
  gem "cucumber"

  # TODO Pinning these for now because github_changelog_generator has a bunch
  # of different versions across our products
  gem "nokogiri", "~> 1.6.3"
  gem "addressable", "~> 2.4.0"
end

# Everything except AIX and Windows
group(:linux, :bsd, :mac_os_x, :solaris) do
  gem "ruby-shadow", platform: :ruby
end

group(:changelog) do
  gem "github_changelog_generator", git: "https://github.com/tduffield/github-changelog-generator", branch: "adjust-tag-section-mapping"
end

# mixlib-install is used by two groups
gem "mixlib-install", :group => [:changelog, :omnibus_package]

# TODO delete this when we figure out how to include the pushy windows dependencies
# correctly
platforms :mswin, :mingw do
  gem "ffi"
  gem "rdp-ruby-wmi"
  gem "windows-api"
  gem "windows-pr"
  gem "win32-api"
  gem "win32-dir"
  gem "win32-event"
  gem "win32-mutex"
  gem "win32-process", "~> 0.8.2"
  gem "win32-service"
end
