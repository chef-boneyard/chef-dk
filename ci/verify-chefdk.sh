#!/usr/bin/env bash

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
                    RUBY_VERSION
do
  unset $ruby_env_var
done

# ACCEPTANCE environment variable will be set on acceptance testers.
# If is it set; we run the acceptance tests, otherwise run rspec tests.
if [ "x$ACCEPTANCE" != "x" ]; then
  export PATH=/opt/chefdk/bin:/opt/chefdk/embedded/bin:$PATH

  set -e

  for GEM_NAME in chef chef-dk
  do

    case "$GEM_NAME" in
     chef) SUITE_NAMES="top-cookbooks" ;;
        *) SUITE_NAMES="" ;;
    esac

    # Force `$WORKSPACE/.bundle/config` to be created so bundler doesn't
    # attempt to create the file up in the `$CHEF_GEM/acceptance/`. This
    # saves us from having to add a `sudo` to any of the `bundle` commands.
    env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID bundle config --local gemfile /opt/chefdk/embedded/lib/ruby/gems/*/gems/$GEM_NAME-[0-9]*/acceptance/Gemfile
    env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID bundle install --deployment
    env KITCHEN_CHEF_PRODUCT=chefdk KITCHEN_CHEF_WIN_ARCHITECTURE=i386 PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID KITCHEN_DRIVER=ec2 KITCHEN_CHEF_CHANNEL=unstable bundle exec chef-acceptance test $SUITE_NAMES --force-destroy --data-path $WORKSPACE/chef-acceptance-data/$GEM_NAME
  done
else
  export PATH=/opt/chefdk/bin:$PATH

  # This has to be the last thing we run so that we return the correct exit code
  # to the Ci system.
  sudo chef verify --unit
fi
