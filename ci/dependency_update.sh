#!/bin/sh

set -evx

bundle install --without omnibus_package test aix bsd linux mac_os_x solaris windows default

bundle exec rake dependencies_ci
