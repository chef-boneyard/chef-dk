#!/bin/sh
#
# Simple file to perform a minimal bundle install to allow Chef Expeditor to run `rake` commands
#

set -evx

# Only install groups required to run the Rake command
export BUNDLE_WITHOUT=omnibus_package:test:aix:bsd:linux:mac_os_x:solaris:windows:default

gem environment
bundler_version=$(grep bundler omnibus_overrides.rb | cut -d'"' -f2)
gem install bundler -v $bundler_version --user-install --conservative
bundle install
