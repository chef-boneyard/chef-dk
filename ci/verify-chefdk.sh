#!/bin/sh

# Default PROJECT_NAME to chefdk
PROJECT_NAME="${PROJECT_NAME:-chefdk}"

# Set up a custom tmpdir, and clean it up before and after the tests
TMPDIR="${TMPDIR:-/tmp}/cheftest"
export TMPDIR
rm -rf $TMPDIR
mkdir -p $TMPDIR

# $PROJECT_NAME is set by Jenkins, this allows us to use the same script to verify
# Chef and Angry Chef
PATH=/opt/$PROJECT_NAME/bin:$PATH
export PATH

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


chef --version
chef-client --version

# Exercise various packaged tools to validate binstub shebangs
$EMBEDDED_BIN_DIR/ruby --version
$EMBEDDED_BIN_DIR/gem --version
$EMBEDDED_BIN_DIR/bundle --version
$EMBEDDED_BIN_DIR/rspec --version

# ffi-yajl must run in c-extension mode or we take perf hits, so we force it
# before running rspec so that we don't wind up testing the ffi mode
FORCE_FFI_YAJL=ext
export FORCE_FFI_YAJL

# ACCEPTANCE environment variable will be set on acceptance testers.
# If is it set; we run the acceptance tests, otherwise run rspec tests.
if [ "x$ACCEPTANCE" != "x" ]; then
  # On acceptance testers we have Chef DK. We will use its Ruby environment
  # to cut down the gem installation time.
  PATH=/opt/chefdk/bin:/opt/chefdk/embedded/bin:$PATH
  export PATH

  # Test against the vendored ChefDK gem
  cd /opt/$PROJECT_NAME/embedded/lib/ruby/gems/*/gems/chef-dk-[0-9]*/acceptance
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD bundle install
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD KITCHEN_DRIVER=ec2 bundle exec chef-acceptance test

  # Test against the vendored Chef gem (run top-cookbooks and windows-service)
  cd /opt/$PROJECT_NAME/embedded/lib/ruby/gems/*/gems/chef-[0-9]*/acceptance
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD bundle install
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD KITCHEN_DRIVER=ec2 bundle exec chef-acceptance test "top-cookbooks|windows-service"
else
  sudo chef verify --unit
fi

# Clean up the tmpdir at the end for good measure.
rm -rf $TMPDIR
