#!/bin/bash
#
# This script runs a passed in command, but first setups up the bundler caching on the repo

set -e

export USER="root"

# make sure we have the aws cli
apt-get update -y
apt-get install awscli -y

# grab the s3 bundler if it's there and use it for all operations in bundler
echo "Fetching bundle cache archive from s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.tar.gz"
aws s3 cp "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.tar.gz" bundle.tar.gz || echo 'Could not pull the bundler archive from s3 for caching. Builds may be slower than usual as all gems will have to install.'
aws s3 cp "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.sha256" bundle.sha256 || echo "Could not pull the sha256 hash of the vendor/bundle directory from s3. Without this we will compress and upload the bundler archive to S3 even if it hasn't changed"

echo "Restoring the bundle cache archive to vendor/bundle"
if [ -f bundle.tar.gz ]; then
  tar -xzf bundle.tar.gz
fi
bundle config --local path vendor/bundle

bundle install --jobs=7 --retry=3
bundle exec $1

if [[ -f bundle.tar.gz && -f bundle.sha256  ]]; then # dont' check the sha if we're missing either file
  if shasum --check bundle.sha256 --status; then # if the the sha matches we're done
    echo "Bundled gems have not changed. Skipping upload to s3"
    exit
  fi
fi

echo "Generating sha256 hash file of the vendor/bundle directory to ship to s3"
shasum -a 256 vendor/bundle > bundle.sha256

echo "Creating the tar.gz to of the vendor/bundle directory to ship to s3"
tar -czf bundle.tar.gz vendor/

echo "Uploading the tar.gz of the vendor/bundle directory to s3"
aws s3 cp bundle.tar.gz "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.tar.gz" || echo 'Could not push the bundler directory to s3 for caching. Future builds may be slower if this continues.'

echo "Uploading the sha256 hash of the vendor/bundle directory to s3"
aws s3 cp bundle.sha256 "s3://public-cd-buildkite-cache/${BUILDKITE_PIPELINE_SLUG}/${BUILDKITE_LABEL}/bundle.sha256" || echo 'Could not push the bundler directory to s3 for caching. Future builds may be slower if this continues.'