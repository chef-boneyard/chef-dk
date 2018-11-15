#
# Copyright 2014-2018, Chef Software Inc.
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
license "Apache-2.0"
license_file "../LICENSE"

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

override :"chef-dk", version: "local_source"

# Load dynamically updated overrides
overrides_path = File.expand_path("../../../../omnibus_overrides.rb", __FILE__)
instance_eval(IO.read(overrides_path), overrides_path)

dependency "preparation"

# For the Delivery build nodes
dependency "delivery-cli"
# This is a build-time dependency, so we won't leave it behind:
dependency "rust-uninstall"

# Leave for last so system git is used for most of the build.
if windows?
  dependency "git-windows"
else
  dependency "git-custom-bindir"
end

dependency "chef-dk"
dependency "chef-dk-gem-versions"

dependency "gem-permissions"
dependency "rubygems-customization"
dependency "shebang-cleanup"

if windows?
  dependency "chef-dk-env-customization"
  dependency "chef-dk-powershell-scripts"
end

dependency "version-manifest"
dependency "openssl-customization"

dependency "stunnel" if fips_mode?

# This *has* to be last, as it mutates the build environment and causes all
# compilations that use ./configure et all (the msys env) to break
if windows?
  override :"ruby-windows-devkit", version: "4.5.2-20111229-1559" if windows_arch_i386?
  dependency "ruby-windows-devkit"
  dependency "ruby-windows-devkit-bash"
  dependency "ruby-windows-system-libraries"
end

dependency "ruby-cleanup"

package :rpm do
  signing_passphrase ENV["OMNIBUS_RPM_SIGNING_PASSPHRASE"]
  compression_level 1
  compression_type :xz
end

package :deb do
  compression_level 1
  compression_type :xz
end

package :pkg do
  identifier "com.getchef.pkg.chefdk"
  signing_identity "Developer ID Installer: Chef Software, Inc. (EU3VF8YLX2)"
end

package :msi do
  fast_msi true
  upgrade_code "AB1D6FBD-F9DC-4395-BDAD-26C4541168E7"
  signing_identity "E05FF095D07F233B78EB322132BFF0F035E11B5B", machine_store: true
  wix_light_extension "WixUtilExtension"
end

package :appx do
  signing_identity "E05FF095D07F233B78EB322132BFF0F035E11B5B", machine_store: true
end

compress :dmg
