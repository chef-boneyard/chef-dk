#!/bin/sh

set -evx

gem environment
bundler_version=$(grep bundler omnibus_overrides.rb | cut -d'"' -f2)
gem install bundler -v $bundler_version --user-install --conservative
export BUNDLE_WITHOUT=omnibus_package:test:aix:bsd:linux:mac_os_x:solaris:windows:default
bundle _${bundler_version}_ install --no-deployment
