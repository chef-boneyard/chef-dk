# Chef Development Kit Changelog

## Unreleased

## Last Release: 0.2.0

### Chef Development Kit Windows Support

Version 0.2.0 of Chef Development Kit is now available as an MSI package for Windows. Supported operating system versions are:

* Windows Server 2008 R2 / Windows 7
* Windows Server 2012 / Windows 8
* Windows Server 2012 R2 / Windows 8.1

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
