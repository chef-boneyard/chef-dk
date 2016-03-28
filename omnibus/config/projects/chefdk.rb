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

# Lower level library pins
override :libedit,             version: "20130712-3.1"
## according to comment in omnibus-sw, latest versions don't work on solaris
# https://github.com/chef/omnibus-software/blob/aefb7e79d29ca746c3f843673ef5e317fa3cba54/config/software/libtool.rb#L23
override :libtool,             version: "2.4.2"
override :libxslt,             version: "1.1.28"
override :makedepend,          version: "1.0.5"
override :rubocop,             version: "v0.37.2"
override :ruby,                version: "2.1.8"
override :rubygems,            version: "2.5.2"
override :"util-macros",       version: "1.19.0"
override :xproto,              version: "7.0.28"
override :yajl,                version: "1.2.1"
override :zlib,                version: "1.2.8"

# override :"libffi",          version: "3.2.1"
# override :"libiconv",        version: "1.14"
# override :"liblzma",         version: "5.2.2"
# override :libxml2,           version: "2.9.3"
# override :"ncurses",         version: "5.9"
# override :"pkg-config-lite", version: "0.28-1"
# override :"libyaml",         version: "0.1.6"

## These can float as they are frequently updated in a way that works for us
#override :"cacerts",                             # probably best to float?
#override :"openssl"                              # leave this?

dependency "preparation"

# All actual dependencies are in chef-dk-complete, so that the addition
# or removal of a dependency doesn't dirty the entire project file
dependency "chef-dk-complete"

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
