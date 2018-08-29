#!/bin/bash

############################################################################
# What is this script?
#
# Chef-DK uses a workflow tool called Expeditor to manage version bumps, changelogs
# and releases. This script updates the version of the Chef gem when a new release
# of Chef is promoted to stable. This repo subscribes to the artifact promotion and
# updates Gemfile then runs bundle update to pull in the new gem.
############################################################################

set -evx

branch="expeditor/chef_${VERSION}"
git checkout -b "$branch"

# make sure we have rake for the tasks later
bundle install
sed -i -r "s/^\s*gem \"chef\".*/  gem \"chef\", \"= ${VERSION}\"/" Gemfile

# it appears that the gem that triggers this script fires off this script before
# the gem is actually available via bundler on rubygems.org.
sleep 120

bundle exec rake dependencies:update

git add .

# give a friendly message for the commit and make sure it's noted for any future audit of our codebase that no
# DCO sign-off is needed for this sort of PR since it contains no intellectual property
git commit --message "Bump Chef to $VERSION" --message "This pull request was triggered automatically via Expeditor when Chef $VERSION was promoted to Rubygems." --message "This change falls under the obvious fix policy so no Developer Certificate of Origin (DCO) sign-off is required."

open_pull_request

# Get back to master and cleanup the leftovers - any changed files left over at the end of this script will get committed to master.
git checkout -
git branch -D "$branch"
