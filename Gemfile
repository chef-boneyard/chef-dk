#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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

source 'https://rubygems.org'

gemspec :name => "chef-dk"

# EXPERIMENTAL: ALL gems specified here will be installed in chef-dk omnibus.
# This represents all gems that will be part of chef-dk.

# All software we recognize needs to stay at the latest possible version. But
# since that's not expressible here, we make it >= the last *known* version to
# at least prevent downgrades beyond that:
gem "appbundler", github: "chef/appbundler", branch: "jk/multiple-gems"
gem "berkshelf"
# Chef 12.8.1 Gem includes some extra files which can break gem installation on
# windows. For now we are pulling chef from github at the tag as a workaround.
gem "chef", github: "chef/chef", branch: "v12.9.7"
gem "cheffish", ">= 2.0.3"
gem "chef-provisioning", ">= 1.6.0"
gem "chef-provisioning-aws", ">= 1.8.0"
gem "chef-provisioning-azure", ">= 0.5.0"
gem "chef-provisioning-fog", ">= 0.18.0"
gem "chef-provisioning-vagrant", ">= 0.11.0"
gem "inspec", ">= 0.17.1"
gem "ohai", ">= 8.13.0"
gem "test-kitchen", ">= 1.6.0"

# All of the following used to be software definitions we included:
gem "chef-vault"
gem "chefspec"
gem "dep-selector-libgecode"
gem "fauxhai"
gem "foodcritic"
gem "kitchen-ec2"
gem "kitchen-inspec"
gem "kitchen-vagrant"
gem "knife-windows"
gem "knife-spork"
gem "nokogiri"
gem "pry"
gem "pry-byebug"
gem "pry-remote"
gem "pry-stack_explorer"
gem "rb-readline"
gem "rubocop", "~> 0.37.2"
gem "winrm-fs"

# bundled or development dependencies we want to ship
gem "dep_selector"
gem "guard"
gem "ruby-prof"
gem "rake"
gem "rdoc"
gem "yard"

gem "jmespath", '< 1.2'


# See `rake dependencies` for the usage of this:

# If we're running out of bin/bundle-platform, we're updating deps. If the platform
# is set to anything other than "ruby," we are doing a platform-specific lockfile,
# and therefore MUST pin all gem versions to the same as the generic Gemfile.lock.
# It is an error if we use different versions anywhere. This ensures that by
# pinning all dependencies to their version in Gemfile.lock.
if File.basename($0) == "bundle-platform" && Gem.platforms != [ "ruby" ]
  puts "platform-bundling for a different platform: #{Gem.platforms.map { |p| p.to_s }}."
  puts "Reading all versions from Gemfile.lock"
  # We ensure everything in windows is pinned to the same version as "generic"
  # by reading the generic Gemfile.lock and pinning to that version in the Gemfile.
  lockfile = File.expand_path("../Gemfile.lock", __FILE__)
  Bundler::LockfileParser.new(IO.read(lockfile)).specs.each do |spec|
    # copy the groups from the existing spec if they are there
    options = {}
    current = dependencies.find { |d| d.name == spec.name }
    if current
      unless current.requirement.satisfied_by?(spec.version)
        puts "WARN: using locked #{spec.name} version #{spec.version} when gemfile asks for #{current}"
      end
      dependencies.delete(current)
      options[:groups] = current.groups
    end
    gem spec.name, spec.version, options
  end
end
