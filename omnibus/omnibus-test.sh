#!/bin/bash
set -ueo pipefail

channel="${CHANNEL:-unstable}"
product="${PRODUCT:-chefdk}"
version="${VERSION:-latest}"

echo "--- Installing $channel $product $version"
package_file="$(/opt/omnibus-toolchain/bin/install-omnibus-product -c "$channel" -P "$product" -v "$version" | tail -n 1)"

echo "--- Verifying omnibus package is signed"
/opt/omnibus-toolchain/bin/check-omnibus-package-signed "$package_file"

sudo rm -f "$package_file"

echo "--- Verifying ownership of package files"

export INSTALL_DIR=/opt/chefdk
NONROOT_FILES="$(find "$INSTALL_DIR" ! -user 0 -print)"
if [[ "$NONROOT_FILES" == "" ]]; then
  echo "Packages files are owned by root.  Continuing verification."
else
  echo "Exiting with an error because the following files are not owned by root:"
  echo "$NONROOT_FILES"
  exit 1
fi

echo "--- Running verification for $channel $product $version"

# This has to be the last thing we run so that we return the correct exit code
# to the Ci system. delivery-cli tests will cause a panic on some platforms
# unless we set the terminal colors just right
sudo TERM=xterm-256color CHEF_FIPS="" CHEF_LICENSE="accept-no-persist" chef verify --unit
