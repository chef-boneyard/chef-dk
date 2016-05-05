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

# Uncomment to pin the chef version
override :chef,             version: "master"
override :ohai,             version: "master"
override :inspec,           version: "master"
override :'kitchen-inspec', version: "master"

override :berkshelf,        version: "master"

override :'test-kitchen',   version: "master"

override :'knife-windows', version: "master"
override :'knife-spork',   version: "master"
override :fauxhai,         version: "master"
override :chefspec,        version: "master"
override :foodcritic,      version: "v6.0.1"

override :bundler,      version: "1.11.2"
override :rubygems,     version: "2.5.2"

override :"chef-vault",   version: "master"

# TODO: Can we bump default versions in omnibus-software?
override :libedit,        version: "20130712-3.1"
override :libtool,        version: "2.4.2"
# override :libxml2,        version: "2.9.3"
override :libxslt,        version: "1.1.28"

if windows?
  override :'ruby-windows', version: "2.1.6"
  if windows_arch_i386?
    override :'ruby-windows-devkit', version: "4.7.2-20130224"
  end
else
  override :ruby,           version: "2.1.6"
end

override :rubocop, version: "v0.37.2"

override :'kitchen-vagrant', version: "master"
override :'winrm-fs',     version: "master"
override :yajl,           version: "1.2.1"
override :zlib,           version: "1.2.8"

# NOTE: the base chef-provisioning gem is a dependency of chef-dk (the app).
# Manage the chef-provisioning version via chef-dk.gemspec.
# TODO delete this when chef-provisioning is released and go back
# to managing the dependency through chef-dk gemspec
override :'chef-provisioning', version: "master"
override :'chef-provisioning-aws', version: "master"
override :'chef-provisioning-azure', version: "master"
override :'chef-provisioning-fog', version: "master"
override :'chef-provisioning-vagrant', version: "master"

dependency "preparation"
dependency "chefdk"
dependency "pry"
dependency "chef-provisioning-aws"
dependency "chef-provisioning-fog"
dependency "chef-provisioning-vagrant"
dependency "chef-provisioning-azure"
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
