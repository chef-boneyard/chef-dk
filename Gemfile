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
  gem "rake"
  gem "pry"
  gem "rdoc"
  gem "yard"
  gem "dep_selector"
  gem "guard"
  gem "cookstyle", ">= 2.0.0"
  gem "foodcritic", ">= 11.2"
end

# We tend to track latest stable release without pinning.
# In order to prevent the depsolver from downgrading we pin some floors with ">=".
# We should only be using "~>" to work around bugs, or temporarily pinning some tech debt.
# We equality pin the chef gem itself to assert which version we're shipping.
group(:omnibus_package) do
  gem "appbundler"
  gem "berkshelf", ">= 6.3"
  gem "chef-provisioning", ">= 2.4.0"
  gem "chef-provisioning-aws", ">= 2.0"
  gem "chef-provisioning-azure", ">= 0.6.0"
  gem "chef-provisioning-fog", ">= 0.20.0"
  gem "chef-vault"
  gem "chef", "= 13.4.19"
  gem "cheffish", ">= 13.0"
  gem "chefspec"
  gem "fauxhai"
  gem "inspec", ">= 0.29.0"
  gem "kitchen-ec2"
  gem "kitchen-dokken", ">= 2.5.0"
  gem "kitchen-hyperv"
  gem "kitchen-inspec"
  gem "kitchen-vagrant"
  gem "knife-windows"
  gem "knife-opc", ">= 0.3.2"
  gem "ohai", ">= 13.1.0"
  gem "test-kitchen"
  gem "listen"
  gem "dco"

  # For Delivery build node
  gem "chef-sugar"
  gem "mixlib-versioning"
  gem "artifactory"
  gem "opscode-pushy-client", ">= 2.3.0"
  gem "ffi-rzmq-core"
  gem "knife-push"

  # All of the following used to be software definitions we included:
  gem "knife-spork"
  gem "dep-selector-libgecode"
  gem "mixlib-install"
  gem "nokogiri"
  gem "pry-byebug"
  gem "pry-remote"
  gem "pry-stack_explorer"
  gem "rb-readline"
  gem "rubocop"
  gem "winrm-fs"
  gem "winrm-elevated"
  gem "cucumber"
  gem "stove"
end

# Everything except AIX
group(:ruby_prof) do
  gem "ruby-prof"
end

# Everything except AIX and Windows
group(:ruby_shadow) do
  gem "ruby-shadow", platform: :ruby
end

gem "chefstyle", group: :test

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
