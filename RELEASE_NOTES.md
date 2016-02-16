# ChefDK 0.11 Release notes

## New / Updated Packages

This version of ChefDK includes a number of key updates to dependent packages:

* chef - updated to 12.7.2
* ohai - updated to 8.10.0
* inspec - updated to 0.11.0
* kitchen-inspec - updated to 0.11.0
* berkshelf - updated to 4.1.1
* test-kitchen - updated to 1.5.0
* knife-windows - updated to 1.2.1
* foodcritic - new dependency, 6.0.0
* rubocop - updated to 0.37.2
* chef-provisioning - updated to 1.6.0
* openssl - updated to 1.0.1r
* CACerts - updated with latest root certificates

## Chef 12.7.2

Please see the Release Notes (https://github.com/chef/chef/blob/master/RELEASE_NOTES.md)
for information on the key changes in Chef 12.7.2.

## Knife-windows 1.2.1

Knife-windows now supports NTLM authentication from Linux.

See the knife-windows Changelog for more details (https://github.com/chef/knife-windows/blob/master/CHANGELOG.md)

## PolicyFile improvements and fixes

There are a number of PolicyFile fixes and improvements:

* Using chef-sugar with Policy files now works (https://github.com/sethvargo/chef-sugar/issues/114).
* Chef export now uses a new repository layout that allows Chef Zero 4.5+ to serve Policyfile content using the native Policyfile APIs. This is mostly noticeable if looking at the generated configuration files.
* Improved Policy logging. Policy files now show policy revision id during runs  (https://github.com/chef/chef-dk/pull/630)
* Better validation - Policy files now validate the recipes in the run list (https://github.com/chef/chef-dk/issues/629).

### Breaking change

ChefDK 0.11.0 generated repos are not backward compatible with older versions of Chef Client.

Repos created by the `chef export` command will only work with Chef Client 12.7 or later. The policyfile_zero provisioner for Test Kitchen uses chef export under the hood, so you will need to configure Test Kitchen to install Chef Client 12.7 or later.

## Improved Windows installer for ChefDK

This release of ChefDK uses an improved Windows MSI-based installer (FastMSI) which speeds up the
installation performance for ChefDK on Windows. The performance improvements will be most
noticeable in clean installs of ChefDK 0.11. In-place upgrade from an earlier version of ChefDK (ie, without
uninstalling the old version) may not show improvements in install time.

## Upgrading from older versions of Chef DK

There is a known issue when upgrading from an older version of Chef DK. In some cases, `knife` commands may fail with a 'missing file' error message. This is because `knife rehash` generates full rather than relative paths, that include the version of the previously installed Chef client.

If this happens, you will need to delete the ~/.chef/plugin_manifest.json file, and run `knife rehash` again.

This issue will be resolved in future releases of Chef DK.
