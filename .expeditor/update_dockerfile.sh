#!/bin/sh

############################################################################
# What is this script?
#
# Chef-DK uses a workflow tool called Expeditor to manage version bumps, changelogs
# and releases. When the current release of Chef-DK is promoted to stable this script
# is run by Expeditor to update the version in the Dockerfile to match the stable
# release.
############################################################################

set -evx

sed -i -r "s/^ARG VERSION=.+/ARG VERSION=${EXPEDITOR_VERSION}/" Dockerfile
