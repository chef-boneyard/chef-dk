#!/bin/sh

set -evx

sed -i -r "s/^ARG VERSION=.+/ARG VERSION=${VERSION}/" Dockerfile
