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
GEM_NAME="chef"

# make sure we have rake for the tasks later
gem install bundler -v 1.17.3 --no-document
bundle _1.17.3_ install
sed -i -r "s/^\s*gem \"chef\".*/  gem \"${GEM_NAME}\", \"= ${VERSION}\"/" Gemfile

tries=12
for (( i=1; i<=$tries; i+=1 )); do
  bundle _1.17.3_ exec rake dependencies:update_gemfile_lock
  new_gem_included && break || sleep 20
  if [ $i -eq $tries ]; then
    echo "Searching for '${GEM_NAME} (${VERSION})' ${i} times and did not find it"
    exit 1
  else
    echo "Searched ${i} times for '${GEM_NAME} (${VERSION})'"
  fi
done

git add .

# give a friendly message for the commit and make sure it's noted for any future audit of our codebase that no
# DCO sign-off is needed for this sort of PR since it contains no intellectual property
git commit --message "Bump Chef to $VERSION" --message "This pull request was triggered automatically via Expeditor when Chef $VERSION was promoted to Rubygems." --message "This change falls under the obvious fix policy so no Developer Certificate of Origin (DCO) sign-off is required."

open_pull_request

# Get back to master and cleanup the leftovers - any changed files left over at the end of this script will get committed to master.
git checkout -
git branch -D "$branch"
