# ChefDK 4.1 Release Notes

## Updated Components

### Chef Infra Client 15.1

Chef Infra Client has been updated to 15.1 with new and improved resources, improvements to target mode, bootstrap bug fixes, new Ohai detection on VirtualBox hosts, and more. See the [Chef Infra Client 15.1 Release Notes](https://github.com/chef/chef/blob/master/RELEASE_NOTES.md#chef-infra-client-151) for a complete list of new and improved functionality.

### Chef InSpec 4.6.9

Chef InSpec has been updated from 4.3.2 to 4.6.9 with the following changes:

  - InSpec `Attributes` have now been renamed to `Inputs` to avoid confusion with Chef Infra attributes.
  - A new InSpec plugin type of `Input` has been added for defining new input types. See the [InSpec Plugins documentation](https://github.com/inspec/inspec/blob/master/docs/dev/plugins.md#implementing-input-plugins) for more information on writing these plugins.
  - InSpec no longer prints errors to the stdout when passing `--format json`.
  - When fetching profiles from GitHub, the URL can now include periods.
  - The performance of InSpec startup has been improved.

### Cookstyle 5.0.0

Cookstyle has been updated to 5.0.0 with a large number of bugfixes and major improvements that lay the groundwork for future autocorrecting of cookobook style and deprecation warnings.

The RuboCop engine that powers Cookstyle has been updated from 0.62 to 0.72, which includes several hundred bugfixes to the codebase. When using Cookstyle 5.0, you may experience existing cookbooks now failing, due to some of these bugfixes. Additionally, some cops have had their names changed and the Rubocop Performance cops have been removed. If you disabled individual cops in your .rubocop.yml file, this may require you update your confg.

This new release also merges in code from the `rubocop-chef` project, providing new alerting and autocorrecting capabilities specific to Chef Infra Cookbooks. Thank you [@coderanger](http://github.com/coderanger) for your work in the rubocop-chef project and [@chrishenry](http://github.com/chrishenry) for helping with new cops.

### Foodcritic 6.1.1

Foodcritic has been updated from 6.0.0 to 6.1.1 with new rules and support for the latest Chef:

- Updated Chef Infra Client metadata for 15.1 to include the new `chocolatey_feature` resources, as well as new properties in the `launchd` and `chocolatey_source` resources
- Added new rule to detect large files shipped in a cookbook: `FC123: Content of a cookbook file is larger than 1MB`. Thanks [@mattray](http://github.com/mattray)
- Allowed configuring the size of the AST cache with a new `--ast-cache-size` command line option. Thanks [@Babar](http://github.com/Babar)

### ChefSpec 7.4.0

ChefSpec has been updated to 7.4 with better support stubbing commands, and a new `policyfile_path` configuration option for specifying the path to the PolicyFile.

### kitchen-dokken 2.7.0

kitchen-dokken has been updated to 2.7.0 with new options for controlling how containers are setup and pulled. You can now disable user namespace mode when running privileged containers with a new `userns_host` config option. There is also a new option `pull_chef_image` (true/false) to control force-pulling the chef image on each run to check for newer images. This option now defaults to `true` so that testing on latest and current always actually mean latest and current. See the [kitchen-digitalocean readme](https://github.com/test-kitchen/kitchen-digitalocean/blob/master/README.md) for `kitchen.yml` config examples.

### kitchen-digitalocean 0.10.4

kitchen-digitalocean has been updated to 0.10.4 with support for new distros and additional configuration options for instance setup. You can now control the default DigitalOcean region systems that are spun up by using a new `DIGITALOCEAN_REGION` env var. You can still modify the region in the driver section of your `kitchen.yml` file if you'd like, and the default region of `nyc1` has not changed. This release also adds slug support for `fedora-29`, `fedora-30`, and `ubuntu-19`. Finally, if you'd like to monitor your test instances, the new `monitoring` configuration option in the `kitchen.yml` driver section allows enabling DigitalOcean's instance monitoring. See the [kitchen-dokken readme](https://github.com/someara/kitchen-dokken/blob/master/README.md) for `kitchen.yml` config examples.

### knife-vsphere 3.0.0

knife-vsphere has been updated to 3.0. This new version adds support for specifying the `bootstrap_template` when creating new VMs. This release also improves how the plugin finds VM hosts, in order to support hosts in nested directories.

## End of Ubuntu 14.04 support

Ubuntu 14.04 entered the end-of-life phase April 30, 2019. Since this version of Ubuntu is now end-of-life, we have stopped building packages for Ubuntu 14.04. If you rely on Ubuntu 14.04 in your environment, we highly recommend upgrading your host to Ubuntu 16.04 or 18.04.

### Security Updates

###  curl 7.65.1

- CVE-2019-5435: Integer overflows in curl_url_set
- CVE-2019-5436: tftp: use the current blksize for recvfrom()
- CVE-2018-16890: NTLM type-2 out-of-bounds buffer read
- CVE-2019-3822: NTLMv2 type-3 header stack buffer overflow
- CVE-2019-3823: SMTP end-of-response out-of-bounds read
- CVE-2019-5443: Windows OpenSSL engine code injection

### cacerts 5-11-2019 release

- Our `cacert` bundle has been updated to the 5-11-2019 bundle, which adds four additional CAs.

# ChefDK 4.0 Release Notes

## Breaking Changes

### Chef EULA

Usage of ChefDK 4.0, Chef Infra Client 15, and InSpec 4 requires accepting the [Chef EULA](https://docs.chef.io/chef_license.html#chef-eula). See the [frequently asked questions](https://www.chef.io/bmc-faq/) for information about the license update and the associated business model change.

### Chef Provisioning

Chef Provisioning is no longer included with Chef DK, and will be officially end of life on August 31, 2019. The source code of Chef Provisioning and the drivers have been moved into the chef-boneyard GitHub organization and will not be further maintained. Current users of Chef Provisioning should contact your Chef Customer Success Manager or Account Representative to review your options.

### `knife bootstrap` against cloud providers

`knife bootstrap` was [rewritten](https://github.com/chef/chef/blob/cfbb01cb5648297835941679bc9638d3a823ad5e/RELEASE_NOTES.md#knife-bootstrap) in Chef Infra Client 15.
The `knife-*` cloud providers need to be updated to use this new API.
As of ChefDK 4.0, `knife bootstrap` functionality against the cloud providers will be broken.
We will fix this ASAP in a ChefDK 4.1 release.
The only gem *not* affected is the `knife-windows` gem.
It has already been re-written to leverage the new bootstrap library.

Affected gems:
* `knife-ec2`
* `knife-google`
* `knife-vsphere`

If you leverage this functionality, please wait to update ChefDK until 4.1 is released with fixes for these gems.

## Improved Chef Generate command

The `chef generate` command has been updated to produce cookbooks and repositories that match Chef's best practices.
  - `chef generate repo` now generates a Chef repository with Policyfiles by default. You can revert to the previous roles / environment behavior with the `--roles` flag.
  - `chef generate cookbook` now generates a cookbook with a Policyfile and no Berksfile by default. You can revert to the previous behavior with the `--berks` flag.
  - `chef generate cookbook` now includes ChefSpecs that utilize the ChefSpec 7.3+ format. This is a much simpler syntax that requires less updating of specs as older platforms are deprecated.
  - `chef generate cookbook` no longer creates cookbook files with the unecessary `frozen_string_literal: true` comments.
  - `chef generate cookbook` no longer generates a full Workflow (Delivery) build cookbook by default. A new `--workflow` flag has been added to allow generating the build cookbook. This flag replaces the previously unused `--delivery` flag.
  - `chef generate cookbook` now generates cookbooks with metadata requiring Chef 14 or later.
  - `chef generate cookbook --kitchen dokken` now generates a fully working kitchen-dokken config.
  - `chef generate cookbook` now generates Test Kitchen configs with the `product_name`/`product_version` method of specifying Chef Infra Client releases as `require_chef_omnibus` will be removed in the next major Test Kitchen release.
  - `chef generate cookbook_file` no longer places the specified file in a "default" folder as these aren't needed in Chef Infra Client 12 and later.
  - `chef generate repo` no longer outputs the full Chef Infra Client run information while generating the repository. Similar to the `cookbook` command you can view this verbose output with the `--verbose` flag.

## Updated Components and Tools

### Chef InSpec 4

Chef InSpec has been updated to 4.3.2 which includes the new InSpec AWS resource pack with **59** new AWS resources, multi-region support, and named credentials support. This release also includes support for auditing systems that use `ed25519` SSH keys.

### Chef Infra Client 15

Chef Infra Client has been updated to Chef 15 with **8** new resources, target mode prototype functionality, `ed25519` SSH key support, and more. See the [Chef Infra Client 15 Release Notes](https://github.com/chef/chef/blob/master/RELEASE_NOTES.md#chef-infra-client-150293) for more details.

### Fauxhai 7.3

Fauxhai has been updated from 6.11 to 7.3. This removes all platforms that were previously marked as deprecated. So if you've noticed deprecation warnings during your ChefSpec tests, you will need to update those specs for the latest [supported Faxhai platforms](https://github.com/chefspec/fauxhai/blob/master/PLATFORMS.md). This release also adds the following new platform releases for testing in ChefSpec:
  - RHEL 6.10 and 8.0
  - openSUSE 15.0
  - CentOS 6.10
  - Debian 9.8 / 9.9
  - Oracle Linux 6.10, 7.5, and 7.6

### Test Kitchen 2.2

Test Kitchen has been updated from 1.24 to 2.2.5. This update adds support for accepting the Chef Infra Client and Chef InSpec EULAs during testing, as well as support for newer `ed25519` format SSH keys on guests. The newer release does remove support for the legacy Librarian depsolver and testing of Chef Infra Client 10/11 releases in some scenarios. See the [Test Kitchen Release Notes](https://github.com/test-kitchen/test-kitchen/blob/master/RELEASE_NOTES.md#test-kitchen-22-release-notes) for additional details on this release.

### Kitchen-ec2 3.0

Kitchen-ec2 has been updated to 3.0, which uses the newer `aws-sdk-v3` and includes a large number of improvements to the driver including improved hostname detection, backoff retries, additional security group configuration options, and more. See the [kitchen-ec2 Changelog](https://github.com/test-kitchen/kitchen-ec2/blob/master/CHANGELOG.md#v300-2019-05-01) for additional details.

### kitchen-dokken 2.6.9

Kitchen-dokken has been updated to 2.6.9 with a new config option `pull_platform_image`, which allows you to disable pulling the platform Docker image on every Test Kitchen converge / test. This is particularly useful for local platform image testing.

kitchen.yml example:
```yaml
driver:
  name: dokken
  pull_platform_image: false
```

# ChefDK 3.11 Release Notes

## Chef Infra Client 14.13.11

Chef Infra Client has been updated to 14.13.11 with resource improvements and bug fixes. See the [Release Notes](https://github.com/chef/chef/blob/chef-14/RELEASE_NOTES.md#chef-client-release-notes-1413) for a detailed list of changes.

## Test Kitchen 1.25

Test Kitchen has been updated to 1.25 with backports of many non-breaking Test Kitchen 2.0 features:

  - Support for accepting the Chef 15 license in Test Kitchen runs. See [Accepting the Chef License](https://docs.chef.io/chef_license_accept.html) for usage details.
  - A new `--fail-fast` command line flag for use with the `concurrency` flag. With this flag set, Test Kitchen will immediately fail when any converge fails instead of continuing to test additional instances.
  - The `policyfile_path` config option now accepts relative paths.
  - A new `berksfile_path` config option allows specifying Berkshelf files in non-standard locations.
  - Retries are now honored when using SSH proxies

## kitchen-dokken 2.7.0
  - The Chef Docker image is now pulled by default so that locally cached `latest` or `current` container versions will be compared to those available on DockerHub. See the [readme](https://github.com/someara/kitchen-dokken#disable-pulling-chef-docker-images) for instructions on reverting to the previous behavior.
  - User namespace mode can be disabled when running privileged containers with a new `userns_host` config option. See the [readme](https://github.com/someara/kitchen-dokken#running-with-user-namespaces-enabled) for details.
  - You can now disable pulling the platform Docker images for local platform image testing or air gapped testing. See the [readme](https://github.com/someara/kitchen-dokken#disable-pulling-platform-docker-images) for details.

## Other Updated Components

- openssl 1.0.2r -> 1.0.2s (bugfix only release)
- cacerts 2019-01-23 -> 2019-05-15

## Security Updates

###  curl 7.65.0

- CVE-2019-5435: Integer overflows in curl_url_set
- CVE-2019-5436: tftp: use the current blksize for recvfrom()
- CVE-2018-16890: NTLM type-2 out-of-bounds buffer read
- CVE-2019-3822: NTLMv2 type-3 header stack buffer overflow
- CVE-2019-3823: SMTP end-of-response out-of-bounds read

# ChefDK 3.10 Release Notes

## New Policyfile Functionality

`include_policy` now supports `:remote` policy files. This new functionality allows you to include policy files over http. Remote policy files require remote cookbooks and `install` will fail otherwise if the included policy file includes cookbooks with paths. Thanks [@mattray](https://github.com/mattray)!

### Other updates

* `kitchen-vagrant`: 1.5.1 -> 1.5.2
* `mixlib-install`: 3.11.12 -> 3.11.18
* `chef`: 14.12.3 -> 14.12.9

# ChefDK 3.9 Release Notes

## Updated Components and Tools

### Chef 14.12.3

ChefDK now ships with Chef 14.12.3. See [Chef 14.12 release notes](https://docs.chef.io/release_notes.html) for more information on what's new.

### InSpec 3.9.0

ChefDK now ships with InSpec 3.9.0. See [InSpec 3.9.0 release details](https://github.com/inspec/inspec/releases/tag/v3.9.0) for more information on what's new.

### Ruby 2.5.5

Ruby has been updated from 2.5.3 to 2.5.5, which includes a large number of bug fixes.

### kitchen-hyperv

kitchen-hyperv has been updated to 0.5.3, which now automatically disables snapshots on the VMs and properly waits for the IP to be set.

### kitchen-vagrant

kitchen-vagrant has been updated to 1.5.1, which adds support for using the new bento/amazonlinux-2 box when setting the platform to amazonlinux-2.

### kitchen-ec2

kitchen-ec2 has been updated to 2.5.0 with support for Amazon Linux 2.0 image searching using the platform 'amazon2'. This release also adds supports Windows Server 1709 and 1803 image searching.

### knife-vsphere

knife-vsphere has been updated to 2.1.3, which adds support for knife's `bootstrap_template` flag and removes the legacy `distro` and `template_file` flags.

### Push Jobs Client

Push Jobs Client has been updated to 2.5.6, which includes significant optimizations and minor bug fixes.

## Security Updates

### Rubygems 2.7.9

Rubygems has been updated from 2.7.8 to 2.7.9 to resolves the following CVEs:

- CVE-2019-8320: Delete directory using symlink when decompressing tar
- CVE-2019-8321: Escape sequence injection vulnerability in verbose
- CVE-2019-8322: Escape sequence injection vulnerability in gem owner
- CVE-2019-8323: Escape sequence injection vulnerability in API response handling
- CVE-2019-8324: Installing a malicious gem may lead to arbitrary code execution
- CVE-2019-8325: Escape sequence injection vulnerability in errors

# ChefDK 3.8 Release Notes

## Updated Components and Tools

### InSpec 3.6.6

ChefDK now ships with Inspec 3.6.6. See [InSpec 3.6.6 release details](https://github.com/inspec/inspec/releases/tag/v3.6.6) for more information on what's new.

### Fauxhai 6.11.0

* Added Windows 2019 Server, Red Hat Linux 7.6, Debian 9.6, and CentOS 7.6.1804.
* Updated Windows7, 8.1, and 10, 2008 R2, 2012, 2012 R2, and 2016 to Chef 14.10.
* Update Oracle Linux 6.8/7.2/7.3/7.4 to Ohai 14.8 in EC2
* Updated the fetcher logic to be compatible with ChefSpec 7.3+. Thanks @oscar123mendoza
* Removed duplicate json data in gentoo 4.9.6

### Mixlib-archive 0.4.20

* Fixes issue #1913. No longer producess corrupted archives on windows. Thanks @kenmacleod for the fix!

### Other updates

* `kitchen-digitalocean`: 0.10.1 -> 0.10.2
* `mixlib-install`: 3.11.5 -> 3.11.11

## Security Updates

### OpenSSL

OpenSSL updated to 1.0.2r to resolve [CVE-2019-1559](https://nvd.nist.gov/vuln/detail/CVE-2019-1559)

# ChefDK 3.7 Release Notes

## Chef 14.10.9

ChefDK now ships with Chef 14.10.9. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## InSpec 3.4.1

ChefDK now ships with InSpec 3.4.1. See <https://github.com/inspec/inspec/releases/tag/v3.4.1> for more information on what's new.

## Updated Components and Tools

### kitchen-inspec 1.0.1

Support bastion configuration in transport options.

### kitchen-vagrant 1.4.0

This fixes audio for virtualbox users by disabling audio in virtualbox by default to prevent interrupting the host's Bluetooth audio.

### kitchen-azurerm 0.14.8

Support Azure Managed Identities and apply vm_tags to all resources in resource group.

### Other updates

* `bundler`: 1.16.1 -> 1.17.3
* `chef-apply`: 0.2.4 -> 0.2.7
* `kitchen-tidy`: 1.2.0 -> 2.0.0
* `rubygems`: 2.7.6 -> 2.7.8

## Deprecations

* `chef provision` - Chef Provisioning has been in maintenance mode since 2015 and due to the age of it's dependencies it cannot be included in ChefDK 4 which is scheduled for an April release. Additional information on the future of Chef Provisioning will be announced in the coming weeks.

# ChefDK 3.6 Release Notes

## Chef 14.8.12

ChefDK now ships with Chef 14.8.12. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## Security Updates

### OpenSSL

OpenSSL updated to 1.0.2q to resolve:
- Microarchitecture timing vulnerability in ECC scalar multiplication ([CVE-2018-5407](https://nvd.nist.gov/vuln/detail/CVE-2018-5407))
- Timing vulnerability in DSA signature generation ([CVE-2018-0734](https://nvd.nist.gov/vuln/detail/CVE-2018-0734))

## New Chef Command Functionality

* New option: `chef generate cookbook --kitchen (dokken|vagrant)` Generate cookbooks with a specific kitchen configuration (defaults to vagrant).

## Updated Components and Tools

### chef-client 14.8

chef-client has been updated from 14.7 to 14.8, which includes resources improvements and bug fixes throughout.

### InSpec 3.2.6

- Added new aws_sqs_queue resource. Thanks [@amitsaha](https://github.com/amitsaha)
- Exposed additional WinRM options for transport, basic auth, and SSPI. Thanks [@frezbo](https://github.com/frezbo)
- Improved UI experience throughout including new CLI flags --color/--no-color and --interactive/--no-interactive

### Berkshelf 7.0.7

- Added `berks outdated --all` command to get a list of outdated dependencies, including those that wouldn't satisfy the version constraints set in Berksfile. Thanks [@jeroenj](https://github.com/jeroenj)

### Fauxhai 6.10.0

- Added Fedora 29 Ohai dump for use in ChefSpec

### chef-sugar 5.0

- Added a new parallels? helper. Thanks [@ehanlon](https://github.com/ehanlon)
- Added support for the Raspberry Pi 1 and Zero to armhf? helper
- Added a centos_final? helper. Thanks [@kareiva](https://github.com/kareiva)

### Foodcritic 15.1

- Updated the Chef metadata to 13.12 / 14.8 and removed all other Chef metadata

### kitchen-azurerm 0.14.7

- Resolved failures in the plugin by updating the azure API gems

### kitchen-ec2 2.4.0

- Added support for arm64 architecture instances
- Support Windows Server 1709 and 1803 image searching. Thanks [@xtimon](https://github.com/xtimon)
- Support Amazon Linux 2.0 image searching. Use the platform 'amazon2'. Thanks [@pschaumburg](https://github.com/pschaumburg)

### knife-ec2 0.19.16

- Allow passing the `--bootstrap-template` option during node bootstrapping

### knife-google 3.3.7

- Allow running knife google zone list, region list, region quotas, project quotas to run without specifyig the `gce_zone` option

### stove 7.0.1

- The yank command has been removed as this command causes large downstream impact to other users and should not be part of the tooling
- The metadata.rb file will now be included in uploads to match the behavior of berkshelf 7+

### test-kitchen 1.24

- Added support for the Chef 13+ root aliases. With this chance you can now test a cookbook with a simple recipe.rb and attributes.rb file.
- Improve WinRM support with retries and graceful connection cleanup. Thanks [@bdwyertech](https://github.com/bdwyertech) and [@dwoz](https://github.com/dwoz)x

# ChefDK 3.5 Release Notes

## Chef 14.7.17

ChefDK now ships with Chef 14.7.17. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## Docker image updates

The [chef/chefdk](https://hub.docker.com/r/chef/chefdk) Docker image now includes graphviz (to support `berks viz`) and rsync (to support `kitchen-dokken`) which makes it a little bigger, but also a little more useful in development and test pipelines.

# ChefDK 3.4 Release Notes

## Chef 14.6.47

ChefDK now ships with Chef 14.6.47. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## Smaller package size

ChefDK RPM and Debian packages are now compressed. Additionally many gems were updated to remove extraneous files that do not need to be included. The download size of packages has decreased accordingly (all measurements in megabytes):

* .deb: 108 -> 84 (22%)
* .rpm: 112 -> 86 (24%)

## Platform Additions

macOS 10.14 (Mojave) is now fully tested and packages are available on downloads.chef.io.

## Updated Tooling

### Fauxhai

Fauxhai has been updated from 6.6.0 to version 6.9.1. This update brings in the latest mocked Ohai run data for use with ChefSpec. This release adds data for Linux Mint 19, macOS 10.14, Solaris 5.11 (11.4 release), and SLES 15. This release also deprecates the following platforms for removal April 2018: Linux Mint 18.2, Gentoo 4.9.6, All versions of ios_xr, All versions of omnios, All versions of nexus, macOS 10.10, and Solaris 5.10. See https://github.com/chefspec/fauxhai/tree/master/lib/fauxhai/platforms for a complete list of non-deprecated platform data for use with ChefSpec.

### Foodcritic

Foodcritic has been updated from 14.1 to 14.3. This updates the metadata that ships with Foodcritic to provide the latest Chef 13.11 and 14.5 metadata, while removing metadata from older Chef releases. This update also removes the FC121 rule, which was causing confusion with community cookbook authors. This rule will be added back when Chef 13 goes EOL in April 2019.

### inSpec 3

This release updates InSpec from 2.2.112 to 3.0.12. This is a major milestone and includes the plugin system, global attributes, enhanced skip messaging, and more. Please head over to https://www.inspec.io/ for a full rundown.

### Kitchen AzureRM

The Kitchen AzureRM driver now supports the Shared Image Gallery.

### Kitchen DigitalOcean

The Kitchen DigitalOcean driver now supports FreeBSD 10.4 and 11.2 in Kitchen configs.

### Kitchen EC2

Kitchen EC2 has been updated to better support Windows systems. The auto-generated security group will now include support for RDP and the log directory will alway be created.

### Kitchen Google

Kitchen Google now includes support for adding labels to instances with a new `labels` config that accepts labels as a hash.

### Knife Windows

Knife Windows has improved Windows detection support to identify Windows 2012r2, 2016, and 10. Additionally when bootstrapping nodes, there is now support for using the client.d directories.

## Security Updates

Ruby has been updated to 2.5.3 to resolve the following vulnerabilities:

- `CVE-2018-16396`: Tainted flags are not propagated in Array#pack and String#unpack with some directives
- `CVE-2018-16395`: OpenSSL::X509::Name equality check does not work correctly

# ChefDK 3.3 Release Notes

## Chef 14.5.33

ChefDK now ships with Chef 14.5.33. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## New Functionality

* New option: `chef update --exclude-deps` for policyfiles will only update the cookbook(s) given on the command line.

## Updated Tooling

### ChefSpec

ChefSpec 7.3.2 greatly simplifies the syntax as well as allows testing of custom resources.
See the [README](https://github.com/chefspec/chefspec/blob/v7.3.2/README.md) and especially the section on
[testing custom resoures](https://github.com/chefspec/chefspec/blob/v7.3.2/README.md#testing-a-custom-resource) for
examples of the new syntax.

## Updated Components and Tools

* `chef-provisioning-aws`: 3.0.4 -> 3.0.6
* `chef-vault`: 3.3.0 -> 3.4.2
* `foodcritic`: 14.0.0 -> 14.1.0
* `inspec`: 2.2.70 -> 2.2.112
* `kitchen-inspec`: 0.23.1 -> 0.24.0
* `kitchen-vagrant`: 1.3.3 -> 1.3.4

## Deprecations

* `chef generate app` - Application repos were a pattern that didn't take off.
* `chef generate lwrp` - Use `chef generate resource`. Every supported release of Chef knows about custom resources. Custom resources are awesome. No one should be writing new LWRPs any more. LWRPS are not awesome.

# ChefDK 3.2 Release Notes

## Chef 14.4.56

ChefDK now ships with Chef 14.4.56. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## New Functionality

* New `chef describe-cookbook` command to display the cookbook checksum.
* Change policyfile generator to use 'policyfiles' directory instead of 'policies' directory

## New Tooling

### Chef Apply

[Chef Apply](https://github.com/chef/chef-apply) is the new gem which provides ad-hoc node management via the `chef-run` binary. It is included in the ChefDK only as a stepping stone towards managing gem resolution in the Chef Workstation repository. Please continue to download and install Chef Workstation if you wish to use the ad-hoc functionality. No guarantees for backwards compatability or functionality are made for the Chef Apply gem when used via the ChefDK.

### Kitchen AzureRM

ChefDK now includes a driver for [Azure Resource Manager](https://github.com/test-kitchen/kitchen-azurerm). This allows Microsoft Azure resources to be provisioned prior to testing. This driver uses the new Microsoft Azure Resource Management REST API via the azure-sdk-for-ruby.

## Updated Tooling

### Test Kitchen

Test Kitchen 1.23 now includes support for [lifecycle hooks](https://github.com/test-kitchen/test-kitchen/blob/master/RELEASE_NOTES.md#life-cycle-hooks).

## Updated Components and Tools

- `berkshelf`: 7.0.4 -> 7.0.6
- `chef-provisioning`: 2.7.1 -> 2.7.2
- `chef-provisioning-aws`: 3.0.2 -> 3.0.4
- `chef-sugar`: 4.0.0 -> 4.1.0
- `fauxhai`: 6.4.0 -> 6.6.0
- `inspec`: 2.1.72 ->2.2.70
- `kitchen-google`: 1.4.0 -> 1.5.0

## Security Updates

### OpenSSL

OpenSSL updated to 1.0.2p to resolve:
- Client DoS due to large DH parameter ([CVE-2018-0732](https://nvd.nist.gov/vuln/detail/CVE-2018-0732))
- Cache timing vulnerability in RSA Key Generation ([CVE-2018-0737](https://nvd.nist.gov/vuln/detail/CVE-2018-0737))

# ChefDK 3.1 Release Notes

## Chef 14.2.0

ChefDK now ships with Chef 14.2.0. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## Habitat packages available

ChefDK is now released as a habitat package under the identifier `chef/chef-dk`. All successful builds will be available in the `unstable` channel and all promoted builds will be available in the `stable` channel. This is similar to the `current` and `stable` downloads of ChefDK available on <https://downloads.chef.io/chefdk/stable>.

## Updated Homebrew cask tap

On macOS you can install ChefDK using `brew cask install chef/chef/chefdk`. This behavior is not new but the tap name changed.

## Updated Tooling

### Fauxhai

Fauxhai 6.4.0 brings support for 3 new platforms - CentOS 7.5, Debian 8.11, and FreeBSD 11.2. It also updates the dumps for Amazon Linux, Redhat, SLES, and Ubuntu to match Chef 14.2 output. Finally it deprecates FreeBSD 10.3.

### Foodcritic

Foodcritic 14.0.0 adds support for Chef 14.2 metadata, makes it the default, and removes old Chef 13 metadata. It also updated rules for clarity, removed an unnecessary rule, and added a new rule saying when cookbooks have unnecessary dependencies now that resources moved into core Chef. See the [changelog](https://github.com/Foodcritic/foodcritic/blob/master/CHANGELOG.md#1400-2018-06-28) for a full list of changes.

### knife-acl

[knife-acl](https://github.com/chef/knife-acl) is now included with ChefDK. This knife plugin allows admin users to modify Chef Server ACLs from their command line.

### knife-tidy

[knife-tidy](https://github.com/chef-customers/knife-tidy) is now included with ChefDK. This knife plugin generates reports about stale nodes and helps clean them up.

### Test Kitchen

Test Kitchen 1.11.0 adds a new `ssh_gateway_port` config and fixed a bug on Unix systems where scripts were not created as executable.

## Updated Components and Tools

- `fauxhai`: 6.3.0 -> 6.4.0
- `foodcritic`: 13.1.1 -> 14.0.0
- `kitchen-digitalocean`: 0.9.8 -> 0.10.0
- `knife-opc`: 0.3.2 -> 0.4.0
- `test-kitchen`: 1.21.2 ->1.22.0

## Security Updates

### OpenSSL

OpenSSL updated to 1.0.2p to resolve:
- Client DoS due to large DH parameter ([CVE-2018-0732](https://nvd.nist.gov/vuln/detail/CVE-2018-0732))
- Cache timing vulnerability in RSA Key Generation ([CVE-2018-0737](https://nvd.nist.gov/vuln/detail/CVE-2018-0737))

- `CVE-2018-1000201`: DLL loading issue which can be hijacked on Windows OS

# ChefDK 3.0 Release Notes

## Chef 14.1.1

ChefDK now ships with Chef 14.1.1. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## Updated Operating System support

ChefDK now ships packages for Ubuntu 18.04 and Debian 9. In accordance with Chef's platform End Of Life policy, ChefDK is no longer shipped on macOS 10.10.

## Enhanced cookbook archive handling

ChefDK now uses an embedded copy of libarchive to support Policyfile and Berkshelf. This improves overall performance and provides a well tested interface to many different types of archives. It also resolves the long standing "not an octal string" problem users face when depending on certain cookbooks in the supermarket.

## Policyfiles: updated `include_policy` support

Policyfiles now support git targets for included policies.

```
include_policy 'base_policy',
               git: 'https://github.com/happychef/chef-repo.git',
               branch: master,
               path: 'policies/base/Policyfile.lock.json'
```

## Policyfiles: `chef update` gains `--exclude-deps` flag

When using this, behavior is very strict: it updates only the cookbook(s)
mentioned on command line.

## Updated Tooling

### Test Kitchen

Test Kitchen has been updated from 1.20.0 to 1.21.2. This release allows you to use a kitchen.yml config file instead of .kitchen.yml so the kitchen config will no longer be hidden in your cookbook directories. It also introduces new config options for SSH proxy servers and allows you to specify multiple paths for data bags. See <https://github.com/test-kitchen/test-kitchen/blob/master/CHANGELOG.md> for the complete list of changes.

### InSpec

InSpec has been updated from 1.51.21 to 2.1.68. InSpec 2.0 brings compliance automation to the cloud, with new resource types specifically built for AWS and Azure clouds. Along with these changes are major speed improvements and quality of life updates. Please visit <https://www.inspec.io> for more information.

### ChefSpec

ChefSpec has been updated to 7.2.1 with Fauxhai 6.2.0. This release removes all platforms that were previously marked as deprecated in Fauxhai. If you saw Fauxhai deprecation warnings during your ChefSpec runs these will now be failures. This update also adds 9 new platforms and updates existing data for Chef 14. To see a complete list of platforms that can be mocked in ChefSpec see <https://github.com/chefspec/fauxhai/blob/master/PLATFORMS.md>.

### Foodcritic

Foodcritic has been updated to from 12.3.0 to 13.1.1. This updates Foodcritic for Chef 13 or later by removing Chef 12 metadata and removing several legacy rules that suggested writing resources in a Chef 12 manner. The update also adds 9 new rules for writing custom resources and updating cookbooks to Chef 13 and 14, resolves several long standing file detection bugs, and improves performance.

### Cookstyle

Cookstyle has been updated to 3.0, which updates the underlying RuboCop engine to 0.55 with a long list of bug fixes and improvements. This release of Cookstyle also enables 19 new rules available in RuboCop. See <https://github.com/chef/cookstyle/blob/master/CHANGELOG.md> for a complete list of newly enabled rules.

### Berkshelf

Berkshelf has been updated to 7.0.2.  Berkshelf 7 moves to using the same libraries as the Chef Client, ensuring consistent behaviour - for instance, ensuring that chefignore files work the same - and enabling a quicker turnaround on bug fixes.  The “Actor crashed” failures of celluloid will no longer be produced by Berkshelf.

### VMware vSphere support

The knife-vsphere plugin for managing VMware vSphere is now bundled with ChefDK.

## Cookbook generator creates a CHANGELOG.md

`chef cookbook generate [cookbook_name]` now creates a `CHANGELOG.md` file.

## Updated Components and Tools

- `chef-provisioning` 2.7.0 -> 2.7.1
- `knife-ec2` 0.17.0 -> 0.18.0
- `opscode-pushy-client` 2.3.0 -> 2.4.11

## Security Updates

### Ruby

Ruby has been updated to 2.5.1 to resolve the following vulnerabilities:

- `CVE-2017-17742`: HTTP response splitting in WEBrick
- `CVE-2018-6914`: Unintentional file and directory creation with directory traversal in tempfile and tmpdir
- `CVE-2018-8777`: DoS by large request in WEBrick
- `CVE-2018-8778`: Buffer under-read in String#unpack
- `CVE-2018-8779`: Unintentional socket creation by poisoned NUL byte in UNIXServer and UNIXSocket
- `CVE-2018-8780`: Unintentional directory traversal by poisoned NUL byte in Dir
- Multiple vulnerabilities in RubyGems

### OpenSSL

OpenSSL has been updated to 1.0.2o to resolve `CVE-2018-0739`.

# ChefDK 2.5 Release Notes

## Rename `smoke` tests to `integration` tests.

The cookbook, recipe, and app generators now name the test directory `integration` instead of `smoke`.

## Chef 13.8.5

ChefDK now ships with Chef 13.8.5. See <https://docs.chef.io/release_notes.html> for more information on what's new.

## Updated chef_version in chef generate cookbook

When running `chef generate cookbook` the generated cookbook will now specify a minimum chef release of 12.14 not 12.1.

## Security Updates

### Ruby

Ruby has been updated to 2.4.3 to resolve `CVE-2017-17405`

### OpenSSL

OpenSSL has been updated to 1.0.2n to resolve `CVE-2017-3738`, `CVE-2017-3737`, `CVE-2017-3736`, and `CVE-2017-3735`.

### LibXML2

LibXML2 has been updated to 2.9.7 to fix `CVE-2017-15412`

### minitar

minitar has been updated to 0.6.1 to resolve `CVE-2016-10173`

## Updated Components

- `chefspec` 7.1.2 -> 7.1.2
- `chef-api` 0.7.1 -> 0.8.0
- `chef-provisioning` 2.6.0 -> 2.7.0
- `chef-provisioning-aws` 3.0.0 -> 3.0.2
- `chef-sugar` 3.6.0 -> 4.0.0
- `foodcritic` 12.2.1 -> 12.3.0
- `inspec` 1.45.13 -> 1.51.21
- `kitchen-dokken` 2.6.5 -> 2.6.7
- `kitchen-ec2` 1.3.2 -> 2.2.1
- `kitchen-inspec` 0.20.0 -> 0.23.1
- `kitchen-vagrant` 1.2.1 -> 1.3.1
- `knife-ec2` 0.16.0 -> 0.17.0
- `knife-windows` 1.9.0 -> 1.9.1
- `test-kitchen` 1.19.2 -> 1.20.0
- `chef-provisioning-azure` has been removed as it used deprecated Azure APIs

# ChefDK 2.4 Release Notes

## Improved Performance Downloading Cookbooks from a Chef Server

Policyfile users who use a Chef Server as a cookbook source will experience faster cookbook downloads when running `chef install`. Chef Server's API requires each file in a cookbook to be downloaded separately; ChefDK will now download the files in parallel. Additionally, HTTP keepalives are enabled to reduce connection overhead.

## Cookbook Artifact Source for Policyfiles

Policyfile users may now source cookbooks from the Chef Server's cookbook artifact store. This is mainly intended to support the upcoming `include_policy` feature, but could be useful in some situations.

Given a cookbook that has been uploaded to the Chef Server via `chef push`, it can be used in another policy by adding code like the following to the ruby policyfile:

```
cookbook "runit",
  chef_server_artifact: "https://chef.example/organizations/myorg",
  identifier: "09d43fad354b3efcc5b5836fef5137131f60f974"
```

## Add include_policy directive
Policyfile maybe now use the `include_policy` directive as described in
[RFC097](https://github.com/chef/chef-rfc/blob/master/rfc097-policyfile-includes.md).
This directive's purpose is to allow the inclusion policyfile locks to the current
policyfile. In this iteration, we support sourcing lock files from a local path or a
chef server. Below is a simple example of how the `include_policy` directive can be used.

Given a policyfile `base.rb`:
```
name 'base'

default_source :supermarket

run_list 'motd'

cookbook 'motd', '~> 0.6.0'
```

Run:
```
>> chef install ./base.rb

Building policy base
Expanded run list: recipe[motd]
Caching Cookbooks...
Using      motd         0.6.4
Using      chef_handler 3.0.2

Lockfile written to /home/jaym/workspace/chef-dk/base.lock.json
Policy revision id: 1238e7a353ec07a4df6636cdffd8805220a00789bace96d6d70268a4b0064023
```

This will produce the `base.lock.json` that will be included in our next policy `users.rb`:
```
name 'users'

default_source :supermarket

run_list 'user'

cookbook 'user', '~> 0.7.0'

include_policy 'base', path: './base.lock.json'
```

Run:
```
>> chef install ./users.rb

Building policy users
Expanded run list: recipe[motd::default], recipe[user]
Caching Cookbooks...
Using      motd         0.6.4
Installing user         0.7.0
Using      chef_handler 3.0.2

Lockfile written to /home/jaym/workspace/chef-dk/users.lock.json
Policy revision id: 20fac68f987152f62a2761e1cfc7f1dc29b598303bfb2d84a115557e2a4a8f27
```

This will produce a `users.lock.json` that has the `base` policyfile lock merged in.

More information can be found in
[RFC097](https://github.com/chef/chef-rfc/blob/master/rfc097-policyfile-includes.md) and
the [docs](https://docs.chef.io/policyfile.htm://docs.chef.io/policyfile.html).

## New tools bundled

We are now shipping the following new tools as part of Chef-DK
  - kitchen-digitalocean
  - kitchen-google
  - knife-ec2
  - knife-google

## Chef Provisioning AWS uses AWS SDK v2

The Chef Provisioning AWS gem has been updated from the Amazon AWS SDK V1 to V2. This includes a huge number of under the hood improvements and bug fixes.

## Notable Updated Gems

- aws-sdk 2.10.45 -> 2.10.90
- chef 13.4.19 -> 13.6.4 ([Changelog](https://github.com/chef/chef/blob/master/RELEASE_NOTES.md))
- chefspec 7.1.0 -> 7.1.1 ([Changelog](https://github.com/chefspec/chefspec/blob/master/CHANGELOG.md)
- chef-provisioning 2.5.0 -> 2.6.0 ([Changelog](https://github.com/chef/chef-provisioning/blob/master/CHANGELOG.md))
- chef-provisioning-aws 2.2.2 -> 3.0.0 ([Changelog](https://github.com/chef/chef-provisioning-aws/blob/master/CHANGELOG.md))
- chef-provisioning-fog 0.21.0 -> 0.26.0 ([Changelog](https://github.com/chef/chef-provisioning-fog/blob/master/CHANGELOG.md))
- chef-sugar 3.5.0 -> 3.6.0 ([Changelog](https://github.com/sethvargo/chef-sugar/blob/master/CHANGELOG.md))
- fauxhai 5.3.0 -> 5.5.0 ([Changelog](https://github.com/chefspec/fauxhai/blob/master/CHANGELOG.md))
- foodcritic 11.4.0 -> 12.2.1 ([Changelog](https://github.com/Foodcritic/foodcritic/blob/master/CHANGELOG.md))
- inspec 1.36.1 -> 1.44.13 ([Changelog](https://github.com/chef/inspec/blob/master/CHANGELOG.md))
- kitchen-digitalocean new @ 0.9.8
- kitchen-google new @ 1.4.0
- kitchen-inspec 0.19.0 -> 0.20.0 ([Changelog](https://github.com/chef/kitchen-inspec/blob/master/CHANGELOG.md))
- knife-ec2 new @ 0.16.0
- knife-google new @ 3.2.0
- knife-spork 1.6.3 -> 1.7.1 ([Changelog](https://github.com/jonlives/knife-spork/blob/master/CHANGELOG.md))
- mixlib-install 2.1.12 -> 3.8.0 ([Changelog](https://github.com/chef/mixlib-install/blob/master/CHANGELOG.md))
- rspec 3.6.0 -> 3.7.0 ([Changelog](https://github.com/rspec/rspec-core/blob/master/Changelog.md))
- serverspec 2.40.0 -> 2.41.3
- test-kitchen 1.17.0 -> 1.19.2 ([Changelog](https://github.com/test-kitchen/test-kitchen/blob/master/CHANGELOG.md))
- train 0.26.2 -> 0.29.2 ([Changelog](https://github.com/chef/train/blob/master/CHANGELOG.md))
- winrm-fs 1.0.1 -> winrm-fs 1.1.1 ([Changelog](https://github.com/WinRb/winrm-fs/blob/master/changelog.md))


# ChefDK 2.3 Release Notes

ChefDK 2.3 includes Ruby 2.4.2 to fix the following CVEs:
  * CVE-2017-0898
  * CVE-2017-10784
  * CVE-2017-14033
  * CVE-2017-14064

The 2.2.1 release includes RubyGems 2.6.13 to fix the following CVEs:
  * CVE-2017-0899
  * CVE-2017-0900
  * CVE-2017-0901
  * CVE-2017-0902

ChefDK 2.3 includes:
  * Chef 13.4.19
  * InSpec 1.36.1
  * Berkshelf 6.3.1
  * Chef Vault 3.3.0
  * Foodcritic 11.4.0
  * Test Kitchen 1.17.0
  * Stove 6.0

## Stove is now included

We are now shipping stove in ChefDK, to aid users in uploading their
cookbooks to supermarkets.

## The cookbook generator now adds a LICENSE file

The cookbook generator now adds a LICENSE file when creating a new
cookbook.


## Boilerplate tests are generated for the CentOS platform
When `chef generate cookbook` is ran, boilerplate unit tests for the CentOS 7 platform are now generated as well.
