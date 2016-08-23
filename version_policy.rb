#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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
  "ruby" => "2.3.1",
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

  ## These can float as they are frequently updated in a way that works for us
  #override "cacerts" =>"???",
  #override "openssl" =>"???",
}

#
# rake dependencies:update_omnibus_overrides (tasks/dependencies.rb) reads this
# and modifies omnibus_overrides.rb
#
# The left side is the software definition name, and the right side is the
# name of the rubygem (gem list -re <rubygem name> gets us the latest version).
#
OMNIBUS_RUBYGEMS_AT_LATEST_VERSION = {
  #rubygems: "rubygems-update", # pinned to 2.6.4 because https://github.com/chef/chef-dk/issues/966
  bundler: "bundler",
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
  "celluloid",
  "celluloid-io",
  "docker-api",
  "fog-cloudatcost",
  "fog-google",
  "gherkin", # fixed in cucumber-core > 1.4.0
  "google-api-client",
  "jwt", # fixed in oauth2 > 1.1.0
  "listen",
  "mime-types",
  "mini_portile2", # dep removed in nokogiri > 1.6.7.2
  "retriable",
  "rubocop",
  "slop", # deo removed in pry > 0.10.3
  "timers",
  "unicode-display_width",
  "varia_model",
  "httpclient",
  "molinillo",
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
  "mixlib-cli"
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
# we do in chef-dk, and the `bundle check` we do to ensure installed gems don't
# have extra deps hiding in their Gemfiles.
#
INSTALL_WITHOUT_GROUPS = %w{
  changelog
  compat_testing
  development
  docgen
  guard
  integration
  maintenance
  test
  tools
  travis
  style
}
