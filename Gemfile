#
# Copyright:: Copyright (c) Chef Software Inc.
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

gem "diff-lcs", "=1.3" # 1.4 breaks diff behavior

gem "chef-telemetry", ">= 1.0.8" # avoid bringing in http dep

group(:omnibus_package, :development, :test) do
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

  # Expeditor manages the version of chef released to Rubygems. We only release 'stable' chef
  # gems to Rubygems now, so letting this float on latest should always give us the latest
  # stable release. May have to re-pin around major version bumping time, or during patch
  # fixes.
  gem "chef", "= 15.14.0"
  gem "chef-bin", "= 15.14.0"
  gem "ohai", ">= 15"
  gem "cheffish", ">= 15", "< 16"
  gem "chef-zero", ">= 15", "< 16"

  # chefspec
  gem "chefspec", ">= 7.3.0", "< 8"
  gem "fauxhai", "~> 7.4"

  # inspec
  gem "inspec-bin", "~> 4.18" # the actual inspec CLI binary
  gem "inspec", "~> 4.18"

  # test-kitchen and plugins
  gem "test-kitchen", ">= 2.0"
  gem "kitchen-azurerm", ">= 0.14"
  gem "kitchen-ec2", ">= 3.0", "< 4"
  gem "kitchen-digitalocean", ">= 0.10.0"
  gem "kitchen-dokken", ">= 2.8.1"
  gem "kitchen-google", ">= 2.0.0"
  gem "kitchen-hyperv", ">= 0.5.1"
  gem "kitchen-inspec", ">= 1.0"
  gem "kitchen-vagrant", ">= 1.6"

  # knife plugins
  gem "knife-acl", ">= 1.0.3"
  gem "knife-azure", ">= 2.0.10"
  gem "knife-ec2", ">= 1.0"
  gem "knife-google", ">= 4.2.0"
  gem "knife-tidy", ">= 1.2.0"
  gem "knife-windows", ">= 3.0"
  gem "knife-opc", ">= 0.4.0"
  gem "knife-vsphere", ">= 4.0"

  # ed25519 ssh key support done here as it's a native gem we can't put in train
  gem "ed25519"
  gem "bcrypt_pbkdf", ">= 1.1.0.rc1"

  # For Delivery build node
  gem "chef-sugar"
  gem "mixlib-versioning"
  gem "artifactory"
  gem "opscode-pushy-client", ">= 2.99"
  gem "ffi-rzmq-core"
  gem "knife-push"

  # All of the following used to be software definitions we included:
  gem "mixlib-archive", ">= 1.0"
  gem "net-ssh", ">= 4.2.0"
  gem "listen"
  gem "dco"
  gem "knife-spork"
  gem "mixlib-install"
  gem "nokogiri", ">= 1.10.9"
  gem "pry-byebug"
  gem "pry-remote"
  gem "pry-stack_explorer"
  gem "rb-readline"
  gem "winrm-fs"
  gem "winrm-elevated"
  gem "cucumber", "< 4" # 4 has breaking changes so don't bring this in
  gem "stove", ">= 7.1.5"
  gem "berkshelf", ">= 7.0.9"
  gem "chef-vault", ">= 3.4.1"
end

# Everything except AIX
group(:ruby_prof) do
  gem "ruby-prof", "< 1.4" # 1.4 introduces a x64-mingw32 gem that causes failures
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
  gem "win32-service", ">= 2.1.5" # 2.1.5 resolves ffi warnings
end
