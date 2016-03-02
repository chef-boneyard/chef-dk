#
# Copyright 2012-2014 Chef Software, Inc.
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
default_version "local_source"

# For the specific super-special version "local_source", build the source from
# the local git checkout. This is what you'd want to occur by default if you
# just ran omnibus build locally.
version("local_source") do
  source path: "#{project.files_path}/../..",
         # Since we are using the local repo, we try to not copy any files
         # that are generated in the process of bundle installing omnibus.
         # If the install steps are well-behaved, this should not matter
         # since we only perform bundle and gem installs from the
         # omnibus cache source directory, but we do this regardless
         # to maintain consistency between what a local build sees and
         # what a github based build will see.
         options: { exclude: [ "omnibus/vendor" ] }
end

# For any version other than "local_source", fetch from github.
if version != "local_source"
  source git: "git://github.com/chef/chef-dk.git"
end

relative_path "chef-dk"

dependency "ruby"

dependency "rubygems"
dependency "bundler"
dependency "appbundler"
# windows does not have native readline support with compiled ruby
dependency "rb-readline" if windows?
dependency "chef"
dependency "test-kitchen"
dependency "inspec"
dependency "kitchen-inspec"
dependency "kitchen-vagrant"
dependency "berkshelf"
dependency "chef-vault"
dependency "foodcritic"
dependency "ohai"
dependency "rubocop"
# This is a TK dependency but isn't declared in that software definition
# because it is an optional dependency but we want to give it to ChefDK users
dependency "winrm-transport"
dependency "openssl-customization"
dependency "knife-windows"
dependency "knife-spork"
dependency "fauxhai"
dependency "chefspec"
dependency "chef-provisioning"

dependency "chefdk-env-customization" if windows?

build do
  env = with_standard_compiler_flags(with_embedded_path).merge(
    # Rubocop pulls in nokogiri 1.5.11, so needs PKG_CONFIG_PATH and
    # NOKOGIRI_USE_SYSTEM_LIBRARIES until rubocop stops doing that
    "PKG_CONFIG_PATH" => "#{install_dir}/embedded/lib/pkgconfig",
    "NOKOGIRI_USE_SYSTEM_LIBRARIES" => "true",
  )

  bundle "install", env: env
  gem "build chef-dk.gemspec", env: env
  gem "install chef-dk*.gem" \
      " --no-ri --no-rdoc" \
      " --verbose", env: env

  appbundle 'berkshelf'
  appbundle 'chefdk'
  appbundle 'chef-vault'
  appbundle 'foodcritic'
  appbundle 'rubocop'
  appbundle 'test-kitchen'
end
