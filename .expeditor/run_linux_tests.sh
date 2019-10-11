#!/bin/sh
#
# This script runs a passed in command, but first setups up the bundler caching on the repo

set -evx

export USER="root"

# make sure we have the aws cli
apt-get update -y
apt-get install awscli -y

# grab the s3 bundler if it's there and use it for all operations in bundler
echo "Fetching bundle cache archive from s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.tar.bz2"
aws s3 cp "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.tar.bz2" bundle.tar.bz2 || echo 'Could not pull the bundler directory to s3 for caching. Builds may be slower than usual as all gems will have to install.'

echo "Restoring the bundle cache archive to vendor/bundle"
tar -xjf bundle.tar.bz2
bundle config --local path vendor/bundle

bundle install --jobs=7 --retry=3
bundle exec $1

# shove the current contents into s3 overwriting the existing bundle if anything changed

echo "Creating the tar.bz2 to of the vendor/bundle directory to ship to s3"
tar -cjf bundle.tar.bz2 vendor/
echo "Uploading the tar.bz2 of the vendor/bundle directory to s3"
aws s3 cp bundle.tar.bz2 "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.tar.bz2" || echo 'Could not push the bundler directory to s3 for caching. Future builds may be slower if this continues.'
