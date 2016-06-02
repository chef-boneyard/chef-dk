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
                    RUBY_VERSION
do
  unset $ruby_env_var
done

# ACCEPTANCE environment variable will be set on acceptance testers.
# If is it set; we run the acceptance tests, otherwise run rspec tests.
if [ "x$ACCEPTANCE" != "x" ]; then
  export PATH=/opt/chefdk/bin:/opt/chefdk/embedded/bin:$PATH

  for GEM_NAME in chef chef-dk
  do

    # copy acceptance suites into workspace
    SUITE_PATH=$WORKSPACE/acceptance-$GEM_NAME
    mkdir -p $SUITE_PATH
    cp -R /opt/chefdk/embedded/lib/ruby/gems/*/gems/$GEM_NAME-[0-9]*/acceptance/. $SUITE_PATH
    sudo chown -R $USER:$USER $SUITE_PATH

    cd $SUITE_PATH

    case "$GEM_NAME" in
     chef) SUITE_NAMES="top-cookbooks" ;;
        *) SUITE_NAMES="" ;;
    esac

    env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID bundle install --deployment
    env KITCHEN_CHEF_PRODUCT=chefdk KITCHEN_CHEF_WIN_ARCHITECTURE=i386 PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID KITCHEN_DRIVER=ec2 KITCHEN_CHEF_CHANNEL=unstable bundle exec chef-acceptance test $SUITE_NAMES --force-destroy --data-path $WORKSPACE/chef-acceptance-data/$GEM_NAME
  done
else
  export PATH=/opt/chefdk/bin:$PATH

  # This has to be the last thing we run so that we return the correct exit code
  # to the Ci system. delivery-cli tests will cause a panic on some platforms
  # unless we set the terminal colors just right
  sudo TERM=xterm-256color chef verify --unit
fi
