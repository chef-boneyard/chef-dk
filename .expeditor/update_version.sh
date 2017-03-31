#!/bin/sh

set -evx

export LANG=en_US.UTF-8

. .expeditor/bundle_install.sh

bundle exec rake expeditor_update_version

git checkout .bundle/config
