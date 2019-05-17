#!/usr/bin/env bash

set -evx

# Cleanning up some cruft from previous tests
sudo find /tmp -name 'chef-dk*' | sudo xargs rm -rf

# Set up a custom tmpdir, and clean it up before and after the tests
TMPDIR="${TMPDIR:-/tmp}/cheftest"
export TMPDIR
rm -rf $TMPDIR
mkdir -p $TMPDIR

# Ensure the calling environment (disapproval look Bundler) does not
# infect our Ruby environment created by the `chef` cli.
for ruby_env_var in _ORIGINAL_GEM_PATH \
                    BUNDLE_BIN_PATH \
                    BUNDLE_GEMFILE \
                    GEM_HOME \
                    GEM_PATH \
                    GEM_ROOT \
                    RUBYLIB \
                    RUBYOPT \
                    RUBY_ENGINE \
                    RUBY_ROOT \
                    RUBY_VERSION \
                    BUNDLER_VERSION
do
  unset $ruby_env_var
done

export PATH=/opt/chefdk/bin:$PATH

# This has to be the last thing we run so that we return the correct exit code
# to the Ci system. delivery-cli tests will cause a panic on some platforms
# unless we set the terminal colors just right
sudo TERM=xterm-256color CHEF_FIPS="" CHEF_LICENSE="accept-no-persist" chef verify --unit
