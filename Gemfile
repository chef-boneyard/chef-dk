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

gemspec

gem "bundler"

group(:omnibus_package, :development, :test) do
  # we pin these gems as they are installed in the ruby source and if we let them
  # float we'll end up with 2 copies shipped in DK. When we bump Ruby we need to
  # look at these pins and adjust them
  gem "rake", "<= 12.3.0"
  gem "rdoc", "<= 6.0.1"
  gem "minitest", "<= 5.10.3"

  gem "pry"
  gem "yard"
  gem "guard"
  gem "cookstyle", "~> 3.0" # bump this on the next DK major release
  gem "foodcritic", "< 16"
  gem "ffi-libarchive", ">= 0.4.0"
end

group(:dep_selector) do
  gem "dep_selector", ">= 1.0.0"
  gem "dep-selector-libgecode"
end

# We tend to track latest stable release without pinning.
# In order to prevent the depsolver from downgrading we pin some floors with ">=".
# We should only be using "~>" to work around bugs, or temporarily pinning some tech debt.
# We equality pin the chef gem itself to assert which version we're shipping.
group(:omnibus_package) do
  gem "appbundler", "< 0.13"
  gem "berkshelf", ">= 7.0.8"
  gem "chef-provisioning", ">= 2.7.1", group: :provisioning
  gem "chef-provisioning-aws", ">= 3.0.2", group: :provisioning
  gem "chef-provisioning-fog", ">= 0.26.1", group: :provisioning
  gem "chef-vault", ">= 3.4.1"
  # Expeditor manages the version of chef released to Rubygems. We only release 'stable' chef
  # gems to Rubygems now, so letting this float on latest should always give us the latest
  # stable release. May have to re-pin around major version bumping time, or during patch
  # fixes.
  gem "chef", "= 14.14.25"
  gem "cheffish", ">= 14.0.1"
  gem "chefspec", ">= 7.3.0", "< 8.0.0" # 8.0 deps on chef-cli so we don't want that
  gem "fauxhai", "~> 6.11" # bump this on the next DK major release
  gem "inspec", "~> 3.9"
  gem "kitchen-azurerm", ">= 0.14"
  gem "kitchen-ec2", ">= 2.3", "< 3.0"
  gem "kitchen-digitalocean", ">= 0.10.0"
  gem "kitchen-dokken", ">= 2.6.7"
  gem "kitchen-google", ">= 2.0.0"
  gem "kitchen-hyperv", ">= 0.5.1"
  gem "kitchen-inspec", ">= 1.0", "< 1.2.0" # 1.2 starts warning on attributes vs. inputs
  gem "kitchen-vagrant", ">= 1.6"
  gem "knife-acl", ">= 1.0.3"
  gem "knife-ec2", ">= 0.19.10"
  gem "knife-google", ">= 3.3.3"
  gem "knife-tidy", ">= 1.2.0"
  gem "knife-windows", ">= 1.9.1"
  gem "knife-opc", ">= 0.4.0"
  gem "knife-vsphere", ">= 3.0.1", "< 4.0"
  gem "mixlib-archive", ">= 0.4.16"
  gem "ohai", "~> 14.0"
  gem "net-ssh", ">= 4.2.0"
  gem "test-kitchen", ">= 1.23.0", "< 2"
  gem "listen"
  gem "dco"

  # Right now we must import chef-apply as a gem into the ChefDK because this is where all the gem
  # dependency resolution occurs. Putting it elsewhere endangers older ChefDK issues of gem version
  # conflicts post-build.
  gem "chef-apply"

  # For Delivery build node
  gem "chef-sugar"
  gem "mixlib-versioning"
  gem "artifactory"
  gem "opscode-pushy-client", ">= 2.99"
  gem "ffi-rzmq-core"
  gem "knife-push"

  # All of the following used to be software definitions we included:
  gem "knife-spork"
  gem "mixlib-install"
  gem "nokogiri"
  gem "pry-byebug"
  gem "pry-remote"
  gem "pry-stack_explorer"
  gem "rb-readline"
  gem "winrm-fs"
  gem "winrm-elevated"
  gem "cucumber"
  gem "stove"
end

# Everything except AIX
group(:ruby_prof) do
  gem "ruby-prof"
end

# Everything except Windows
group(:ruby_shadow) do
  gem "ruby-shadow", platform: :ruby
end

gem "chefstyle", group: :test

# Ensure support for push-client on Windows
platforms :mswin, :mingw do
  gem "rdp-ruby-wmi"
  gem "windows-pr"
  gem "win32-api"
  gem "win32-dir"
  gem "win32-event"
  gem "win32-mutex"
  gem "win32-process", "~> 0.8.2"
  gem "win32-service"
end
