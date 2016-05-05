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
  
  cd /opt/chefdk/embedded/lib/ruby/gems/*/gems/chef-[0-9]*/acceptance
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD bundle install
  sudo env KITCHEN_CHEF_PRODUCT=chefdk KITCHEN_CHEF_WIN_ARCHITECTURE=i386 PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD KITCHEN_DRIVER=ec2 bundle exec chef-acceptance test top-cookbooks --force-destroy

  cd /opt/$PROJECT_NAME/embedded/lib/ruby/gems/*/gems/chef-dk-[0-9]*/acceptance
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD bundle install
  sudo env KITCHEN_CHEF_PRODUCT=chefdk KITCHEN_CHEF_WIN_ARCHITECTURE=i386 PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD KITCHEN_DRIVER=ec2 bundle exec chef-acceptance test --force-destroy
else
  export PATH=/opt/chefdk/bin:$PATH

  # This has to be the last thing we run so that we return the correct exit code
  # to the Ci system.
  sudo chef verify --unit
fi
