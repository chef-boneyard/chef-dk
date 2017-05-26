#!/bin/sh

set -evx

export LANG=en_US.UTF-8

bundle install --without omnibus_package test aix bsd linux mac_os_x solaris windows default

bundle exec rake ci_version_bump
