#!/bin/bash
#
# Tests for the Chef-DK habitat package.
# Assume package has already been installed.
#

set -eo pipefail

# Execute all commands that currently work
echo -n "Chef Inspec "
inspec -v
echo "Chef Infra"
echo -n " - knife "
knife -v | awk {'print $NF'}
echo -n " - chef-client "
chef-client -v | awk {'print $NF'}
echo -n " - chef-solo "
chef-solo -v | awk {'print $NF'}
echo -n " - chef-apply "
chef-apply -v | awk {'print $NF'}
echo -n " - chef-shell "
chef-shell -v | awk {'print $NF'}
# TODO(afiune) do we still use this? because it doesn't work
echo " - chef-zero (not-working)"
#chef-zero -v
echo -n "Berkshelf "
berks -v
cookstyle -v
foodcritic -V
ohai -v
kitchen -v
echo "Chef-Vault (only-help)"
chef-vault -h

# TODO(afiune) fix this since it currently doesn't work
echo "skip: Chef CLI (not-working)"
#chef -v

# TODO(afiune) add more tests
