#!/bin/bash
#
# Build chef-dk hart package and run the integration tests
#

set -eo pipefail

log_line() {
    echo "--- [$(date -u)] $*"
}

export HAB_ORIGIN=chef
export HAB_STUDIO_SUP=false
export HAB_NONINTERACTIVE=true
export HAB_LICENSE="accept-no-persist"

log_line "generate ephemeral origin key"
hab origin key generate $HAB_ORIGIN

log_line "build chef-dk hart package"
hab pkg build .

log_line "install chef-dk hart package"
source "results/last_build.env"
hab pkg install -b "results/$pkg_artifact"

log_line "run chef-dk integration tests"
./habitat/tests.sh
