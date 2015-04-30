# Chef Development Kit Changelog

# 0.5.1:
* [#368](https://github.com/chef/chef-dk/pull/368): Fixing undefined_method
  error when performing `chef diff`
* Updating Chef dependency to version 12.3.0

# 0.5.0:
* [#345](https://github.com/chef/chef-dk/pull/345): Support fish
  shell in `chef shell-init`
* [Omnibus-Chef #337](https://github.com/chef/omnibus-chef/pull/337):
  Fix a ruby warning for redefined method in rubygems customization that
  interacted poorly with certain Ruby plugins for text editors.
* [#327](https://github.com/chef/chef-dk/pull/327) `chef -v` now displays the
  version of the ChefDK, Chef, Berkshelf and Test Kitchen.
* [#150](https://github.com/chef/chef-dk/pull/150) Update `generate repo`
  command to no longer use monolithic repo.
* [#263](https://github.com/chef/chef-dk/pull/263) Add a `chef_repo` cookbook
  source which can be used in place of supermarket/berks-like depsolving to
  support a single monolithic git repo with its 'universe' of cookbooks entirely
  contained within it.  Cookbook dependencies will be determined only from the
  filesystem.  Cannot be combined with supermarket/berks-apis as a source.
* [#305](https://github.com/chef/chef-dk/pull/305) Updated Test Kitchen
  policyfile provisioner to work in Test Kitchen 1.4
* Including `knife-windows` plugin inside the Omnibus ChefDK builds.
* Including `winrm-transport` plugin inside the Omnibus ChefDK builds,
  used by Test Kitchen to connect to windows guests.
* Updated dependencies (some bundled with the omnibus build)
  * Chef - 12.2.1
  * chef-provisioning - 1.1.1
  * chef-provisioning-fog - 0.13.2
  * chef-provisioning-azure - 0.3.2
  * chef-provisioning-aws - 1.1.1
  * test-kitchen - 1.4.0
  * kitchen-vagrant - 0.17.0
  * knife-windows - 0.8.4
  * winrm-transport - 1.0.0
  
## Policyfiles

* [#323](https://github.com/chef/chef-dk/pull/323) Add `revision_id` to
  policyfile locks, which provides a unique identifier for a generated lock.
* [#351](https://github.com/chef/chef-dk/pull/351) Add attributes to
  policyfiles.
* [#359](https://github.com/chef/chef-dk/pull/359) Add the ability for users to
  update only the attributes of their policyfile.lock by running `chef update -a`.
* [#352](https://github.com/chef/chef-dk/pull/352) Fixed bug where attributes
  would be modified in policyfile.lock during cookbook updates.
* [#359](https://github.com/chef/chef-dk/pull/359) Add a `chef diff` command to
  show diffs between policyfile locks locally, in git, and on a Chef Server.
* [#342](https://github.com/chef/chef-dk/pull/342) Fixed bug where a cookbook
  with no source options couldn't be added to the Policyfile.rb
* [#362](https://github.com/chef/chef-dk/pull/362): Policyfile native
  API mode is now the default. Add `policy_document_native_api false` to
  your config file to continue to use the compatibility mode.
    * Chef Zero has not yet been updated; Chef Zero users should continue to use
    compatibility mode (`policy_document_native_api false`) for Policyfiles.
    * This new API will be enabled by default in the next version of Chef
    Server (12.1.0).

# 0.4.0
* Add support for uploading Policyfiles via native API rather than as a
  data bag item. This requires an unreleased version of the Chef Server
  and Chef Client to work, so it is disabled by default. Configure
  `policy_document_native_api true` to enable.

# 0.3.6
* Support cookbooks that contain only `metadata.json` with Policyfiles.
* Add named run lists to the Policyfile DSL. The feature however, is not
  usable until support is added to Chef Client.
* Allow generator cookbooks to have arbitrary names. The
  argument to `--generator-cookbook` should be the path to the cookbook,
  rather than the path to the directory containing the generator
  cookbook.
* Custom Generator cookbooks can now be configured in
  `~/.chef/config.rb` (or `knife.rb`) by setting
  `chefdk.generator_cookbook`.
* Added `chef update` command, which rebuilds `Policyfile.lock.json`
  to reflect any changes in the `Policyfile.rb` and updates cookbooks to
  the latest versions that match the dependency constraints.
* Added `chef export` command. This command creates a directory
  containing all cookbooks referenced by the `Policyfile.lock.json` and
  a copy of the lock file as a data bag item. This directory can be
  served by Chef Zero to apply your policy to a node.
* Added `policyfile_zero` Test Kitchen provisioner. This provisioner
  converges chef-client in policyfile mode using Chef Zero. This
  currently requires TK to be modified to use mixlib-shellout 2.x, which
  will be addressed in the next TK release.
* [Omnibus-Chef #318](https://github.com/opscode/omnibus-chef/pull/318):
  Will no longer install gem documentation when using `chef gem`.
  This speeds up gem installs.
* Powershell support for `chef shell-init`
* `chef generate` will now generate ChefSpec tests for new recipes, and ServerSpec tests when a kitchen.yml is generated

# 0.3.5
* Update Chef to 11.18.0 RC0, resolves issue with knife loading commands
  from incompatible versions installed as gems. See:
  https://github.com/opscode/chef-dk/issues/227
* Use the correct separator when joining paths on windows:
  https://github.com/opscode/chef-dk/pull/232 fixes #180

# 0.3.4
* Rollback appbundler to 0.2.0, resolves
  https://github.com/opscode/chef-dk/issues/228
* Update components: Berks 3.2.0, Chef 11.16.4, Bundler 1.7.5

# 0.3.3

* [**Martin Smith**](https://github.com/martinb3): Add the ability to
specify arbitrary context attributes in generators from the command
line. Attributes are specified by passing the `--generator-arg` option
to a `chef generate` command with arguments of the form `key=value`. For
example, if you pass the option `--generator-arg database=mysql`, you
can access this in generator recipes with
`ChefDK::Generator.context.database` (which will return `"mysql"` in
this example).
* Fix bug in `chef verify` when prerelease ChefSpec is installed
* Include chef-provisioning and AWS, Azure, Vagrant and Fog drivers
* Fix erchef incompatibility in `chef push`
* Search upwards for `.git` dir when generating metadata for Policyfile
  locks.

# 0.3.2

* Revert the packaged certificate bundle to the '2014.08.20' version.
This works around an issue where SSL connections to AWS would fail with
certificate validation errors. More information can be found in
[#199](https://github.com/opscode/chef-dk/issues/199).
* Enforce mode 0644 for the CA cert bundle in omnibus packaging; A
change to omnibus resulted in this file being mode 0600, preventing
non-root users from verifying SSL certificates.

# 0.3.1

* Add a generator for Policyfiles
* Fix a regression in Windows packaging; the build step to upgrade the
OpenSSL version within the package was inadvertently removed, causing
certificate validation to fail in some contexts.

# 0.3.0

* [**Robert J. Berger**](https://github.com/rberger):
  Use Gem.user_dir instead of Gem.paths.home for GEM_HOME in chef exec.
* [**the Bunny Man**](https://github.com/tbunnyman):
  Treat existence of git and skip_git flag correctly in the generators.

* Initial Release of the Policyfile feature. This feature relies on
updates to the server API before it is production-ready, though it
provides a compatibility mode for testing purposes. The Policyfile
feature is accessed via the `chef install` and `chef push` commands. See
POLICYFILE_README.md in this repo for further information about the
feature and its current limitations.
* CLI no longer dumps stack trace when given invalid options
* Update Unix ruby to 2.1.3 from 2.1.2
* Warn when embedded/bin directory exists before bin directory in ENV['PATH']

# 0.2.2

* Fix a regression where `chef generate template` fails with
  `undefined method `content_source' for #<chefdk::generator::context:0x00000003e37af8>`
  in 0.2.1

## 0.2.1

Other than some minor bug fixes, here is a list of included changes:

* Chef DK is now supported on Mac 10.8.
* Fixed a bug in `chef exec` to set the ENV correctly. This resolves errors like
  [this](https://github.com/opscode/chef-dk/issues/103) when running commands
  with `chef exec`.
* Make supermarket the default source in generated Gemfiles.
* `chef generate repo` command is now available. This command generates a chef
  repository which is equivalent to [chef-repo](https://github.com/opscode/chef-repo).
* Generators do not require Administrator privileges on Windows anymore.

## 0.2.0

### Chef Development Kit Windows Support

Version 0.2.0 of Chef Development Kit is now available as an MSI package for Windows. Supported operating system versions are:

* Windows Server 2008 R2 / Windows 7
* Windows Server 2012 / Windows 8
* Windows Server 2012 R2 / Windows 8.1

### Added `chef shell-init`
`chef shell-init SHELL_NAME` emits shell commands that modify your
environment to make ChefDK your primary ruby. For more information to
help you decide if this is desirable and instructions, see "Using ChefDK
as Your Primary Development Environment" in the README.

### Added option to generate subcommand

The 'chef generate' subcommand now has the '--generator-cookbook' option to let you
specify a path to an alternate skeleton cookbook for generating cookbooks. For an
example, look at 'lib/chef-dk/skeletons' which is the default if this option
is not specified. Your cookbook will need to be named `code_generator` in order
for the recipes to be run.

* [Add skeleton option for chef generate](https://github.com/opscode/chef-dk/pull/40) by [martinisoft](https://github.com/martinisoft)

### Added subcommand

The 'chef exec' subcommand added to execute commands with the PATH and ruby environment
of the chefdk omnibus environment (analogous to 'bundle exec').

* [chef exec](https://github.com/opscode/chef-dk/pull/22)

## Release: 0.1.0

### Berkshelf Updates

Berkshelf is updated to 3.1.1. [(Berkshelf Changelog)](https://github.com/berkshelf/berkshelf/blob/master/CHANGELOG.md)

ChefDK changes for Berkshelf 3.1.1:

* [Integration test fixes](https://github.com/opscode/chef-dk/pull/26)
* [Unit test fixes](https://github.com/opscode/chef-dk/pull/23)

### Test Kitchen Updates

ChefDK now includes the `kitchen-vagrant` driver by default. Other
drivers can be installed via `chef gem`. Additionally, Test Kitchen has
been updated to install drivers to the embedded ruby when using `kitchen init`.

* [Test Kitchen gem install fix](https://github.com/test-kitchen/test-kitchen/pull/416)
* [kitchen init bug report](https://github.com/opscode/chef-dk/issues/15)

### `verify` Command Improvements:

Runs a set of smoke tests by default; Can independently run smoke,
unit and/or integration tests.

* [chef verify patch](https://github.com/opscode/chef-dk/pull/25)
* [chef verify failure on OS X](https://github.com/opscode/chef-dk/issues/21)
* [chef verify failure as non-root](https://github.com/opscode/chef-dk/issues/13)

### `gem` Command Improvements:

Gems now install in "user" mode by default, and are installed to
`~/.chefdk/gem`. Executables will be installed to
`~/.chefdk/gem/ruby/2.1.0/bin`. See [the notes on the README](https://github.com/opscode/chef-dk#using-chefdk-as-your-primary-development-environment)
for more information about updating your environment to use ChefDK as
your primary Ruby development environment.

* [chef gem should work as non-root](https://github.com/opscode/chef-dk/issues/11)

### Improved Documentation

The README now has basic usage instructions for the `chef` command line
tool and documents how it interacts (or doesn't) with other Ruby
development tools.

* [Update README](https://github.com/opscode/chef-dk/issues/24)
* [Explain how ChefDK affects my workflow](https://github.com/opscode/chef-dk/issues/16)

### Added Tool

`chef-vault` is now a part of the default package.
