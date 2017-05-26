#
# Copyright:: Copyright (c) 2016-2017, Chef Software Inc.
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

# Explicit omnibus overrides.
OMNIBUS_OVERRIDES = {
  # Until 1.13.0 is released
  :bundler => "1.14.6",
  # Lower level library pins
  ## according to comment in omnibus-sw, latest versions don't work on solaris
  # https://github.com/chef/omnibus-software/blob/aefb7e79d29ca746c3f843673ef5e317fa3cba54/config/software/libtool.rb#L23
  "libffi" => "3.2.1",
  "libiconv" => "1.14",
  "liblzma" => "5.2.2",
  ## according to comment in omnibus-sw, the very latest versions don't work on solaris
  # https://github.com/chef/omnibus-software/blob/aefb7e79d29ca746c3f843673ef5e317fa3cba54/config/software/libtool.rb#L23
  "libtool" => "2.4.2",
  "libxml2" => "2.9.4",
  "libxslt" => "1.1.29",
  "libyaml" => "0.1.6",
  "makedepend" => "1.0.5",
  "ncurses" => "5.9",
  "pkg-config-lite" => "0.28-1",
  "ruby" => "2.4.1",
  # Leave dev-kit pinned to 4.5 on 32-bit, because 4.7 is 20MB larger and we don't want
  # to unnecessarily make the client any fatter. (Since it's different between
  # 32 and 64, we have to do it in the project file still.)
  # "ruby-windows-devkit" => "4.5.2-20111229-1559",
  "ruby-windows-devkit-bash" => "3.1.23-4-msys-1.0.18",
  "util-macros" => "1.19.0",
  "xproto" => "7.0.28",
  "zlib" => "1.2.8",
  # The windows dependency (libzmq4x-windows) only has 1 version so far in
  # software def so we don't need to override that
  "libzmq" => "4.0.5",

  # Match what is in Chef Client
  "openssl" => "1.0.2j",
}

#
# rake dependencies:update_omnibus_overrides (tasks/dependencies.rb) reads this
# and modifies omnibus_overrides.rb
#
# The left side is the software definition name, and the right side is the
# name of the rubygem (gem list -re <rubygem name> gets us the latest version).
#
OMNIBUS_RUBYGEMS_AT_LATEST_VERSION = {
  rubygems: "rubygems-update",
  # bundler: "bundler", # pinned to 1.12.5 until we figure out how we're failing on 1.13.0
}

#
# rake dependencies:check (tasks/dependencies.rb) uses this as a list of gems
# that are allowed to be outdated according to `bundle updated`
#
# Once you decide that the list of outdated gems is OK, you can just
# add gems to the output of bundle outdated here and we'll parse it to get the
# list of outdated gems.
#
ACCEPTABLE_OUTDATED_GEMS = [
  "activesupport",     # anchored by outdated google-api-client
  "celluloid",         # ridley requires 0.16.x
  "celluloid-io",      # ridley requires 0.16.x
  "cucumber-core",     # Until cucumber 2.0
  "fog-cloudatcost",   # fog restricts this for probably no good reason
  "fog-dynect",        # fog restricts this for probably no good reason
  "fog-google",        # fog-google 0.2+ requires Ruby 2.0+, fog 2.0.0 will include it
  "google-api-client", # chef-provisioning-fog restricts to < 0.9 for presently unknown reasons
  "json",              # inspec pins this because Ruby 2.0, no eta on fix
  "rbvmomi",           # fog-vsphere restricts this to a patch version, not sure why
  "retriable",         # anchored by outdated google-api-client
  "rubocop",           # cookstyle pins older releases by design
  "slop",              # expected to disappear with pry 0.11
  "timers",            # anchored by outdated celluloid
  "github_changelog_generator", # we use a forked version that differs from rubygems
  "addressable",       # sawyer limits to < 2.6
  "faraday",           # ridely restrcits this 0.9.x
  "thor",              # berkshelf restricts this to < 0.19.2
  "nokogiri",          # fog limits to ~> 1.5
  "mixlib-install",    # test kitchen limits to less than 3.x

  # We have a task called update_stable_channel_gems which scans and pins to the
  # latest released chef/chef-config/opscode-pushy-client but it pulls from the
  # chef repo instead of from rubygems. Bundler currently considers any git
  # source at the same version (or lower) than one available from rubygems as
  # outdated and hence fails the outdated gem test, confusing Julia bot.

  # Therefore..  turn checks on both of them off. If and when the rake task for
  # update_stable_channel_gems changes, this exclusion can be revisited.
  "chef",
  "chef-config",
  "opscode-pushy-client",
  "mixlib-cli",

]

#
# Some gems are part of our bundle (must be installed) but not important
# enough to lock. We allow `bundle install` in test-kitchen, berks, etc.
# to use their own versions of these.
#
# This mainly tells you which gems `chef verify` allows you to install and
# run.
#
GEMS_ALLOWED_TO_FLOAT = [
  "rubocop", # different projects disagree in their dev dependencies
  "unicode-display_width", # dep of rubocop
  "powerpack", # dep of rubocop
  "cookstyle", # has a runtime dep on rubocop
]

#
# The list of groups we install without: this drives both the `bundle install`
# we do in chef-dk, and the `bundle check` we do to ensure installed gems dont
# have extra deps hiding in their Gemfiles.
#
INSTALL_WITHOUT_GROUPS = %w{
  changelog
  compat_testing
  deploy
  development
  docgen
  guard
  integration
  maintenance
  test
  tools
  travis
  style
  simulator
}
