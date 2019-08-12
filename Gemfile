#
# Copyright:: Copyright (c) 2014-2019 Chef Software Inc.
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
  gem "rake", "<= 12.3.2"
  gem "rdoc", "<= 6.0.1"
  gem "minitest", "<= 5.10.3"

  gem "pry"
  gem "yard"
  gem "guard"
  gem "cookstyle", "~> 5.0"
  gem "foodcritic", ">= 16.0"
  gem "ffi-libarchive"
end

group(:dep_selector) do
  gem "dep_selector"
  gem "dep-selector-libgecode"
end

# We tend to track latest stable release without pinning.
# In order to prevent the depsolver from downgrading we pin some floors with ">=".
# We should only be using "~>" to work around bugs, or temporarily pinning some tech debt.
# We equality pin the chef gem itself to assert which version we're shipping.
group(:omnibus_package) do
  gem "appbundler"
  gem "berkshelf", ">= 7.0.5"
  gem "chef-vault", ">= 3.4.1"
  # Expeditor manages the version of chef released to Rubygems. We only release 'stable' chef
  # gems to Rubygems now, so letting this float on latest should always give us the latest
  # stable release. May have to re-pin around major version bumping time, or during patch
  # fixes.
  gem "chef", "= 15.2.20"
  gem "chef-bin", "= 15.2.20"
  gem "cheffish", ">= 14.0.1"
  gem "chefspec", ">= 7.3.0", "< 8"
  gem "fauxhai", "~> 7.0"
  gem "inspec-bin", "~> 4.10" # the actual inspec CLI binary
  gem "inspec", "~> 4.10"
  gem "kitchen-azurerm", ">= 0.14"
  gem "kitchen-ec2", ">= 3.0", "< 4"
  gem "kitchen-digitalocean", ">= 0.10.0"
  gem "kitchen-dokken", ">= 2.6.7"
  gem "kitchen-google", ">= 2.0.0"
  gem "kitchen-hyperv", ">= 0.5.1"
  gem "kitchen-inspec", ">= 1.0"
  gem "kitchen-vagrant", ">= 1.6"
  gem "knife-acl", ">= 1.0.3"
  gem "knife-ec2", ">= 1.0"
  gem "knife-google", ">= 3.3.3"
  gem "knife-tidy", ">= 1.2.0"
  gem "knife-windows", ">= 1.9.1"
  gem "knife-opc", ">= 0.4.0"
  gem "knife-vsphere", ">= 2.1.1"
  gem "mixlib-archive", ">= 0.4.16"
  gem "ohai", ">= 14"
  gem "net-ssh", ">= 4.2.0"
  gem "test-kitchen", ">= 1.23"
  gem "listen"
  gem "dco"

  # many layers down these bring in ethon which uses ffi / libcurl and breaks on windows
  # we want to get this working, but for now it's disabled so we can get a build out
  # make sure to add curl back to the omnibus def before enabling this again
  # gem "knife-vcenter", ">= 2.0"
  # gem "kitchen-vcenter", ">= 2.0"

  # ed25519 ssh key support done here as it's a native gem we can't put in train
  gem "ed25519"
  gem "bcrypt_pbkdf"

  # Right now we must import chef-apply as a gem into the ChefDK because this is where all the gem
  # dependency resolution occurs. Putting it elsewhere endangers older ChefDK issues of gem version
  # conflicts post-build.
  # Version 3.3 switches to ChefCLI instead of ChefDK - we want to lock to
  # the latest version before that so that we don't pull in ChefCLI.
  gem "chef-apply", "= 0.3.0"

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

# TODO delete this when we figure out how to include the pushy windows dependencies
# correctly
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
