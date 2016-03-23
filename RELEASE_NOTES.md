# ChefDK 0.12 Release notes

## New / Updated Packages

This version of ChefDK includes a number of key updates to dependent packages:

* chef - updated to 12.8.1
* ohai - updated to 8.12.1
* inspec - updated to 0.15.0
* kitchen-inspec - updated to 0.12.13
* berkshelf - updated to 4.3.0
* test-kitchen - updated to 1.6.0
* knife-windows - updated to 1.4.0
* foodcritic - updated, 6.0.1
* openssl - updated to 1.0.1s
* chefspec - updated 4.6.0
* winrm-fs - new dependency 0.3.2

## Chef 12.8.1

Please see the Release Notes (https://github.com/chef/chef/blob/master/RELEASE_NOTES.md)
for information on the key changes in Chef 12.8.1.

## Knife-windows 1.4.0

* Users can specify the architecture they want to install on the target system during knife bootstrap windows.
* `client.rb` can enforce FIPS mode.
* A SSL fingerprint can be specified when using self signed certificates.
* Support for Extended Protection for Authentication (aka Chennel Binding) over SSL.

See the knife-windows Changelog for more details (https://github.com/chef/knife-windows/blob/master/CHANGELOG.md)

## Berkshelf 4.3.0

Supports downloading universe from chef servers.

See the berkshelf Changelog for more details (https://github.com/berkshelf/berkshelf/blob/master/CHANGELOG.md)

## Test-Kitchen 1.6.0

* Fixes WinRM authorization errors using kitchen-inspec
* Adds a `chef_apply` provisioner

Lots of other bug fixes and improvements can be found in the test-kitchen changelog (https://github.com/test-kitchen/test-kitchen/blob/master/CHANGELOG.md)
