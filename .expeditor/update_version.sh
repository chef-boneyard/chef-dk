#!/bin/sh
#
# After a PR merge, Chef Expeditor will bump the PATCH version in the VERSION file.
# It then executes this file to update any other files/components with that new version.
#

set -evx

sed -i -r "s/^(\s*)VERSION = \".+\"/\1VERSION = \"$(cat VERSION)\"/" lib/chef-dk/version.rb

# There is a bug (https://github.com/bundler/bundler/issues/5644) that is preventing
# us from updating the chef-dk gem via `bundle update` or `bundle lock --update`.
# Until that is addressed, let's replace the version using sed.
sed -i -r "s/chef-dk\s\(.+\)$/chef-dk \($(cat VERSION)\)/" Gemfile.lock

# Once Expeditor finshes executing this script, it will commit the changes and push
# the commit as a new tag corresponding to the value in the VERSION file.
