# Chef Development Kit

[![Build Status Master](https://travis-ci.org/chef/chef-dk.svg?branch=master)](https://travis-ci.org/chef/chef-dk)
[![Build Status Master](https://ci.appveyor.com/api/projects/status/github/chef/chef-dk?branch=master&svg=true&passingText=master%20-%20Ok&pendingText=master%20-%20Pending&failingText=master%20-%20Failing)](https://ci.appveyor.com/project/Chef/chef-dk/branch/master)
[![](https://img.shields.io/badge/Release%20Policy-Cadence%20Release-brightgreen.svg)](https://github.com/chef/chef-rfc/blob/master/rfc086-chef-oss-project-policies.md#cadence-release)

Chef Development Kit (ChefDK) brings Chef and the development tools developed by the Chef Community together and acts as the consistent interface to this awesomeness. This awesomeness is composed of:

* [Chef][]
* [Berkshelf][]
* [Test Kitchen][]
* [ChefSpec][]
* [Foodcritic][]
* [Cookstyle][]
* [Delivery CLI][]
* [Push Jobs Client][]

This repository contains the code for the `chef` command. The full
package is built with omnibus. Project and component build definitions
are in the omnibus directory in this repository.

## Installation

You can get the [latest release of ChefDK from the downloads page][ChefDK].

On Mac OS X, you can also use [homebrew-cask](https://caskroom.github.io/)
to `brew cask install chefdk`.

Once you install the package, the `chef-client` suite, `berks`,
`kitchen`, and this application (`chef`) will be symlinked into your
system bin directory, ready to use.

### Pre-release Candidates

The following commands will download the latest ChefDK package from the `current` channel.  The `current` channel holds builds that have passed testing and are candidates for release.
More information about flags supported by install.sh available here: https://docs.chef.io/api_omnitruck.html

#### Linux and OS/X:

In a terminal, run:

`curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -c current -P chefdk`

To download a specific version, append the `-v` flag.  EG, `-v 0.9.0`.

#### Windows

Open up a Powershell command prompt as Administrator and run:

`. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -channel current -project chefdk`

To download a specific version, append the `-version` flag.  EG, `-version 0.9.0`.

## Usage

For help with [Berkshelf][], [Test Kitchen][], [ChefSpec][], [Foodcritic][], [Delivery CLI][] or [Push Jobs Client][],
visit those projects' homepages for documentation and guides. For help with
`chef-client` and `knife`, visit the [Chef documentation][]
and [Learn Chef][].

### The `chef` Command

Our goal is for `chef` to become a workflow tool that builds on the
ideas of Berkshelf to provide an awesome experience that encourages
quick iteration and testing (and makes those things easy) and provides a
way to easily, reliably, and repeatably roll out new automation code to
your infrastructure.

While we've got a long way to go before we reach that goal we do have
some helpful bits of functionality already included in the `chef`
command:

#### `chef generate`
The generate subcommand generates skeleton Chef code
layouts so you can skip repetitive boilerplate and get down to
automating your infrastructure quickly. Unlike other generators, it only
generates the minimum required files when creating a cookbook so you can
focus on the task at hand without getting overwhelmed by stuff you don't
need.

The following generators are built-in:

* `chef generate app` Creates an "application" layout that supports
multiple cookbooks. This is a somewhat experimental compromise between
the one-repo-per-cookbook and monolithic-chef-repo styles of cookbook
management.

* `chef generate cookbook` Creates a single cookbook.
* `chef generate recipe` Creates a new recipe file in an existing
cookbook.
* `chef generate attribute` Creates a new attributes file in an existing
cookbook.
* `chef generate template` Creates a new template file in an existing
cookbook. Use the `-s SOURCE` option to copy a source file's content to
populate the template.
* `chef generate file` Creates a new cookbook file in an existing
cookbook. Supports the `-s SOURCE` option similar to template.
* `chef generate lwrp` Creates a new LWRP resource and provider in an
existing cookbook.

The `chef generate` command also accepts additional `--generator-arg key=value`
pairs that can be used to supply ad-hoc data to a generator cookbook.
For example, you might specify `--generator-arg database=mysql` and then only
write a template for `recipes/mysql.rb` if `context.database == 'mysql'`.

#### `chef gem`
`chef gem` is a wrapper command that manages installation and updating
of rubygems for the Ruby installation embedded in the ChefDK package.
This allows you to install knife plugins, Test Kitchen drivers, and
other Ruby applications that are not packaged with ChefDK.

Gems are installed to a `.chefdk` directory in your home directory; any
executables included with a gem you install will be created in
`~/.chefdk/gem/ruby/2.1.0/bin`. You can run these executables with
`chef exec`, or use `chef shell-init` to add ChefDK's paths to your
environment. Those commands are documented below.

### `chef exec`
`chef exec <command>` runs any arbitrary shell command with the PATH
environment variable and the ruby environment variables (`GEM_HOME`,
`GEM_PATH`, etc.) setup to point at the embedded ChefDK omnibus environment.

### `chef shell-init`
`chef shell-init SHELL_NAME` emits shell commands that modify your
environment to make ChefDK your primary ruby. It supports bash, zsh,
fish and PowerShell (posh). For more information to help you decide if
this is desirable and instructions, see "Using ChefDK as Your Primary
Development Environment" below.

### `chef install`
`chef install` reads a `Policyfile.rb` document, which contains a
`run_list` and optional cookbook version constraints, finds a set of
cookbooks that provide the desired recipes and meet dependency
constraints, and emits a `Policyfile.lock.json` describing the expanded
run list and locked cookbook set. The `Policyfile.lock.json` can be used
to install the cookbooks on another machine. The policy lock can be
uploaded to a Chef Server (via the `chef push` command) to apply the
expanded run list and locked cookbook set to nodes in your
infrastructure. See the POLICYFILE_README.md for further details.

### `chef push`
`chef push POLICY_GROUP` uploads a Policyfile.lock.json along with the cookbooks it
references to a Chef Server. The policy lock is applied to a
`POLICY_GROUP`, which is a set of nodes that share the same run list and
cookbook set. This command operates in compatibility mode and has the
same caveats as `chef install`. See the POLICYFILE_README.md for further
details.

### `chef update`
`chef update` updates a Policyfile.lock.json with the latest cookbooks
from upstream sources. It supports an `--attributes` flag which will
cause only attributes from the Policyfile.rb to be updated.

### `chef diff`
`chef diff` shows an itemized diff between Policyfile locks. It can
compare Policyfile locks from local disk, git, and/or the Chef Server,
based on the options given.

#### `chef verify`
`chef verify` tests the embedded applications. By default it runs a
quick "smoke test" to verify that the embedded applications are
installed correctly and can run basic commands. As an end user this is
probably all you'll ever need, but `verify` can also optionally run unit
and integration tests by supplying the `--unit` and `--integration`
flags, respectively.

You can also focus on a specific suite of tests by passing it as an argument.
For example `chef verify git` will only run the smoke tests for the `git` suite.

*WARNING:* The integration tests will do dangerous things like start
HTTP servers with access to your filesystem and even create users and
groups if run with sufficient privileges. The tests may also be
sensitive to your machine's configuration. If you choose to run these,
we recommend to only run them on dedicated, isolated hosts (we do this
in our build cluster to verify each build).

### Using ChefDK as Your Primary Development Environment

By default, ChefDK only adds a few select applications to your `PATH`
and packages them in such a way that they are isolated from any other
Ruby development tools you have on your system. If you're happily using
your system ruby, rvm, rbenv, chruby or any other development
environment, you can continue to do so. Just ensure that the ChefDK
provided applications appear first in your `PATH` before any
gem-installed versions and you're good to go.

If you'd like to use ChefDK as your primary Ruby/Chef development
environment, however, you can do so by initializing your shell with
ChefDK's environment.

To try it temporarily, in a new terminal session, run:

```sh
eval "$(chef shell-init SHELL_NAME)"
```

where `SHELL_NAME` is the name of your shell (usually bash, but zsh is
also common). This modifies your `PATH` and `GEM_*` environment
variables to include ChefDK's paths (run without the `eval` to see the
generated code). Now your default `ruby` and associated tools will be
the ones from ChefDK:

```sh
which ruby
# => /opt/chefdk/embedded/bin/ruby
```

To add ChefDK to your shell's environment permanently, add the
initialization step to your shell's profile:

```sh
echo 'eval "$(chef shell-init SHELL_NAME)"' >> ~/.YOUR_SHELL_PROFILE
```

Where `YOUR_SHELL_PROFILE` is `~/.bash_profile` for most bash users,
`~/.zshrc` for zsh, and `~/.bashrc` on Ubuntu.

#### Powershell

You can use `chef shell-init` with PowerShell on Windows.

To try it in your current session:

```posh
chef shell-init powershell | Invoke-Expression
```

To enable it permanently:

```posh
"chef shell-init powershell | Invoke-Expression" >> $PROFILE
```

#### Fish

`chef shell-init` also supports fish.

To try it:

```fish
eval (chef shell-init fish)
```

To permanently enable:

```fish
echo 'eval (chef shell-init SHELL_NAME)' >> ~/.config/fish/config.fish
```

## Uninstallation Instructions

### Mac OS X

You can uninstall Chef Development Kit on Mac using the below commands.

First, remove the main package files:

```sh
# Remove the installed files
sudo rm -rf /opt/chefdk

# Remove the system installation entry
sudo pkgutil --forget com.getchef.pkg.chefdk
```

Next, remove the symlinks which the Chef Development Kit installs. The
location for these differs based on your OS X version.

Pre-El Capitan:

```sh
# Symlinks are in /usr/bin
ls -la /usr/bin | egrep '/opt/chefdk' | awk '{ print $9 }' | sudo xargs -I % rm -f /usr/bin/%
```

Post-El Capitan:

```sh
# Symlinks are in /usr/local/bin
ls -la /usr/local/bin | egrep '/opt/chefdk' | awk '{ print $9 }' | sudo xargs -I % rm -f /usr/local/bin/%
```

### Windows

You can use `Add / Remove Programs` on Windows to remove the Chef Development
Kit from your system.

### RHEL

You can use `rpm` to uninstall Chef Development Kit on RHEL based systems:

```sh
rpm -qa *chefdk*
yum remove <package>
rm -rf /opt/chefdk
rm -rf ~/.chefdk
```

### Ubuntu

You can use `dpkg` to uninstall Chef Development Kit on Ubuntu based systems:

```sh
dpkg --list | grep chefdk # or dpkg --status chefdk

# Purge chefdk from the system.
# see man dkpg for details
dpkg -P chefdk
```

## Contributing

For information on contributing to this project see <https://github.com/chef/chef/blob/master/CONTRIBUTING.md>

# For ChefDK Developers

See the [Development Guide](CONTRIBUTING.md) for how to get started with
development on the ChefDK itself, as well as details on how dependencies,
packaging, and building works.

- - -

[Berkshelf]: https://docs.chef.io/berkshelf.html "Berkshelf"
[Chef]: https://www.chef.io/chef/ "Chef"
[ChefDK]: https://downloads.chef.io/chefdk "Chef Development Kit"
[Chef Documentation]: https://docs.chef.io "Chef Documentation"
[ChefSpec]: http://chefspec.github.io/chefspec/ "ChefSpec"
[Cookstyle]: https://docs.chef.io/cookstyle.html "Cookstyle"
[Foodcritic]: http://foodcritic.io "Foodcritic"
[Learn Chef]: https://learn.chef.io "Learn Chef"
[Test Kitchen]: http://kitchen.ci "Test Kitchen"
[Delivery CLI]: https://docs.chef.io/delivery_cli.html "Delivery CLI"
[Push Jobs Client]: https://docs.chef.io/push_jobs.html#push-jobs-client "Push Jobs Client"
