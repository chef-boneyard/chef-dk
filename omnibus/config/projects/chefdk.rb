#
# Copyright 2014-2016 Chef Software, Inc.
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

name "chefdk"
friendly_name "Chef Development Kit"
maintainer "Chef Software, Inc. <maintainers@chef.io>"
homepage "https://www.chef.io"

build_iteration 1
require_relative "../../../lib/chef-dk/version"
build_version ChefDK::VERSION

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir "#{default_root}/opscode/#{name}"
else
  install_dir "#{default_root}/#{name}"
end

override :ruby, version: "2.1.8"
override :'ruby-windows-devkit', version: "4.7.2-20130224" if windows? && windows_arch_i386?
override :bundler,      version: "1.11.2"
override :rubygems,     version: "2.5.2"

# Uncomment to pin the chef version
override :chef,             version: "12.8.1"
override :ohai,             version: "v8.12.1"
override :inspec,           version: "v0.15.0"
override :'kitchen-inspec', version: "v0.12.3"

override :berkshelf,        version: "v4.3.0"
override :'dep-selector-libgecode', version: "1.2.0"

override :'test-kitchen',   version: "v1.6.0"

override :'knife-windows', version: "v1.4.0"
override :'knife-spork',   version: "1.6.1"
override :fauxhai,         version: "v3.1.0"
override :chefspec,        version: "v4.6.0"
override :foodcritic,      version: "v6.0.1"

override :bundler,      version: "1.11.2"
override :rubygems,     version: "2.5.2"

override :"chef-vault",   version: "v2.8.0"

# TODO: Can we bump default versions in omnibus-software?
override :libedit,        version: "20130712-3.1"
override :libtool,        version: "2.4.2"
# override :libxml2,        version: "2.9.3"
override :libxslt,        version: "1.1.28"

override :rubocop, version: "v0.37.2"

override :'kitchen-vagrant', version: "v0.19.0"
override :'winrm-fs',     version: "v0.3.2"
override :yajl,           version: "1.2.1"
override :zlib,           version: "1.2.8"

# NOTE: the base chef-provisioning gem is a dependency of chef-dk (the app).
# Manage the chef-provisioning version via chef-dk.gemspec.
override :'chef-provisioning-aws', version: "v1.8.0"
override :'chef-provisioning-azure', version: "v0.5.0"
override :'chef-provisioning-fog', version: "v0.16.0"
override :'chef-provisioning-vagrant', version: "v0.11.0"

dependency "preparation"
dependency "chefdk"
dependency "pry"
dependency "chef-provisioning-aws"
dependency "chef-provisioning-fog"
dependency "chef-provisioning-vagrant"
dependency "chef-provisioning-azure"
dependency "ruby-windows-devkit" if windows?
dependency "rubygems-customization"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"
dependency "clean-static-libs"

package :rpm do
  signing_passphrase ENV['OMNIBUS_RPM_SIGNING_PASSPHRASE']
end

package :pkg do
  identifier "com.getchef.pkg.chefdk"
  signing_identity "Developer ID Installer: Chef Software, Inc. (EU3VF8YLX2)"
end

package :msi do
  fast_msi  true
  upgrade_code "AB1D6FBD-F9DC-4395-BDAD-26C4541168E7"
  signing_identity "F74E1A68005E8A9C465C3D2FF7B41F3988F0EA09", machine_store: true
  wix_light_extension "WixUtilExtension"
end

compress :dmg
