#!/bin/sh
#
# This script runs a passed in command, but first setups up the bundler caching on the repo

set -evx

export USER="root"
apt-get update -y
apt-get install awscli -y
aws s3 sync "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundler" vendor/bundle || echo 'Could not pull the bundler directory to s3 for caching. Builds may be slower than usual as all gems will have to install.'
bundle config --local path vendor/bundle
bundle install --jobs=7 --retry=3
bundle exec $1
aws s3 sync vendor/bundle "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundler" || echo 'Could not push the bundler directory to s3 for caching. Future builds may be slower if this continues.'
