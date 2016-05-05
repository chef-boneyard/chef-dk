# Chef Development Kit

Chef Development Kit (ChefDK) brings Chef and the development tools developed by the Chef Community together and acts as the consistent interface to this awesomeness. This awesomeness is composed of:

* [Chef][]
* [Berkshelf][]
* [Test Kitchen][]
* [ChefSpec][]
* [Foodcritic][]

This repository contains the code for the `chef` command. The full
package is built with omnibus. Project and component build definitions
are in the omnibus directory in this repository.

## Installation

You can get the [latest release of ChefDK from the downloads page][ChefDK].

On Mac OS X, you can also use [homebrew-cask](http://caskroom.io)
to `brew cask install chefdk`.

Once you install the package, the `chef-client` suite, `berks`,
`kitchen`, and this application (`chef`) will be symlinked into your
system bin directory, ready to use.

### Pre-release Candidates

The following commands will download the latest ChefDK package from the `current` channel.  The `current` channel holds builds that have passed testing and are candidates for release.

#### Linux and OS/X:

In a terminal, run:

`curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -c current -P chefdk`

To download a specific version, append the `-v` flag.  EG, `-v 0.9.0`.

#### Windows

Open up a Powershell command prompt as Administrator and run:

`. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -channel current -project chefdk`

To download a specific version, append the `-version` flag.  EG, `-version 0.9.0`.

## Usage

For help with [Berkshelf][], [Test Kitchen][], [ChefSpec][] or [Foodcritic][],
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

Next, remove the symlinks which the Chef Development Kit installs. The location for these differs based on your OS X version.

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

# For ChefDK Developers

## Building the ChefDK

To build the chef-dk, we use the omnibus system. Go to the [omnibus README](omnibus/README.md) to find out how to build!

To update the chef-dk's dependencies, run `rake dependencies`. This will update the `Gemfile.lock`, `Gemfile.windows.lock` and `omnibus/Gemfile.lock`, and show you any outdated dependencies. Some outdated dependencies are to be expected; it will inform you if any new ones appear that we don't know about, and tell you how to proceed.

To add or remove a package from the chef-dk, edit `Gemfile`.

# How the ChefDK Builds and Versions

The ChefDK is an amalgam of many components. These components update all the time, necessitating new builds. This is an overview of the process of versioning, building and releasing the ChefDK.

## ChefDK Packages

The ChefDK is distributed as packages for debian, rhel, ubuntu, windows and os/x. It includes a large number of components from various sources, and these are versioned and maintained separately from the chef-dk project, which bundles them all together conveniently for the user.

These packages go through several milestones:
- `master`: When code is checked in to master, the patch version of chef-dk is bumped (e.g. 0.9.10 -> 0.9.11) and a build is kicked off automatically to create and test the packages in Chef's Jenkins cluster.
- `unstable`: When a package is built, it enters the unstable channel. When all packages for all OS's have successfully built, the test phase is kicked off in Jenkins across all supported OS's. These builds are password-protected and generally only available to the test systems.
- `current`: If the packages pass all the tests on all supported OS's, it is promoted as a unit to `current`, and is available via Chef's artifactory by running `curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -c current -P chefdk`
- `stable`: Periodically, Chef will pick a release to "bless" for folks who would like a slower update schedule than "every time a build passes the tests." When this happens, it is manually promoted to stable and an announcement is sent to the list. It can be reached at https://downloads.chef.io or installed using the `curl` command without specifying `-c current`. Packages in `stable` are no longer available in `current`.

Additionally, periodically Chef will update the desired versions of chef-dk components and check that in to `master`, triggering a new build with the updated components in it.

## Automated Version Bumping

Whenever a change is checked in to `master`, the patch version of `chef-dk` is bumped. To do this, the `lita-versioner` bot listens to github for merged PRs, and when it finds one, takes these actions:

1. Bumps the patch version in `lib/chef-dk/version.rb` (e.g. 0.9.14 -> 0.9.15).
2. Runs `rake dependencies:update_conservative` to update the `Gemfile.lock` and `Gemfile.windows.lock` to include the new version.
3. Pushes to `master` and submits a new build to Chef's Jenkins cluster.

## Component Versions

The chef-dk has two sorts of component: ruby components like `berkshelf` and `test-kitchen`, and binary components like `openssl` and even `ruby` itself.

In general, you can find all chef-dk desired versions in the [Gemfile](Gemfile) and [chef-dk-overrides](omnibus/config/files/chef-dk-overrides.rb) files. The [Gemfile.lock](Gemfile.lock) is the locked version of the Gemfile. [build](omnibus/Gemfile) and [test](acceptance/Gemfile) Gemfiles and [Berksfile](omnibus/Berksfile) version the toolset we use to build and test.

### Binary Components

The versions of binary components (as well as rubygems and bundler, which can't be versioned in a Gemfile) are stored in [chef-dk-overrides.rb](omnibus/config/files/chef-dk-overrides.rb).  `rake dependencies` will update the `bundler` version, and the rest are be updated manually by Chef every so often.

These have software definitions either in [omnibus/config/software](omnibus/config/software) or, more often, in the [omnibus-software](https://github.com/chef/omnibus-software/tree/master/config/software) project.

### Rubygems Components

Most of the actual front-facing software in the chef-dk is composed of ruby projects. berkshelf, test-kitchen and even chef itself are made of ruby gems. Chef uses the typical ruby way of controlling rubygems versions, the `Gemfile`. Specifically, the `Gemfile` at the top of the chef-dk repository governs the version of every single gem we install into the chef-dk package. It's a one-stop shop.

Our rubygems component versions are locked down with `Gemfile.lock` and `Gemfile.windows.lock` (which affects windows), and can be updated with `rake dependencies`.

**Windows**: [Gemfile.lock](Gemfile.lock) is generated platform-agnostic. In order to keep windows versions in sync, [Gemfile.windows](Gemfile.windows) reads the generic Gemfile.lock and explicitly pins all gems to those versions, allowing bundler to bring in windows-specific versions of the gems and new deps, but requiring that all gems shared between Windows and Unix have the same version.

The tool we use to generate Windows-specific lockfiles on non-Windows machines is [tasks/bundle-platform](bundle-platform), which takes the first argument and sets `Gem.platforms`, and then calls `bundle` with the remaining arguments.

### Build Tooling Versions

Of special mention is the software we use to build omnibus itself. There are two distinct bits of code that control the versions of compilers, make, git, and other tools we use to build.

First, the Jenkins machines that run the build are configured entirely by the [opscode-ci cookbook](https://github.com/chef-cookbooks/opscode-ci) cookbook. They install most of the tools we use via `build-essentials`, and standardize the build environment so we can tear down and bring up builders at will. These machines are kept alive long-running, are periodically updated by Chef to the latest opscode-ci, omnibus and build-essentials cookbooks.

Second, the version of omnibus we use to build the chef-dk is governed by `omnibus/Gemfile`. When software definitions or the omnibus framework is updated, this is the file that drives whether we pick it up.

The omnibus tooling versions are locked down with `omnibus/Gemfile.lock`, and can be updated by running `rake dependencies`.

### Test Versions

chef-dk is tested by the [chef-acceptance framework](https://github.com/chef/chef-acceptance), which contains suites that are run on the Jenkins test machines. The definitions of the tests are in the `acceptance` directory. The version of chef-acceptance and test-kitchen, are governed by `acceptance/Gemfile`.

The test tooling versions are locked down with `acceptance/Gemfile.lock`, which can be updated by running `rake dependencies`.

## The Build Process

The actual ChefDK build process is done with Omnibus, and has several general steps:

1. `bundle install` from `chef-dk/Gemfile.lock`
2. Reinstall any gems that came from git or path using `rake install`
3. appbundle chef, chef-dk, test-kitchen and berkshelf
4. Put miscellaneous powershell scripts and cleanup

### Kicking Off The Build

The build is kicked off in Jenkins by running this on the machine (which is already the correct OS and already has the correct dependencies, loaded by the `omnibus` cookbook):

```
load-omnibus-toolchain.bat
cd chef-dk/omnibus
bundle install
bundle exec omnibus build chefdk
```

This causes the [chefdk project definition](omnibus/config/projects/chefdk.rb) to load, which runs the [chef-dk-complete](omnibus/config/software/chef-dk-complete.rb) software definition, the primary software definition driving the whole build process. The reason we embed it all in a software definiton instead of the project is to take advantage of omnibus caching: omnibus will invalidate the entire project (and recompile ruby, openssl, and everything else) if you change anything at all in the project file. Not so with a software definition.

### Installing the Gems

The primary build definition that installs the many ChefDK rubygems is [`software/chef-dk.rb`](omnibus/software/chef-dk.rb). This has dependencies on any binary libraries, ruby, rubygems and bundler. It has a lot of steps, so it uses a [library](omnibus/files/chef-dk/build-chef-dk.rb) to help reuse code and make it manageable to look at.

What it does:

1. Depends on software defs for pre-cached gems (see "Gems and Caching" below).
2. Installs all gems from the bundle:
   - Sets up a `.bundle/config` ([code](omnibus/files/chef-dk/build-chef-dk.rb#L17-L39)) with --retries=4, --jobs=1, --without=development,no_<platform>, and `build.config.nokogiri` to pass.
   - Sets up a common environment, standardizing the compilers and flags we use, in [`env`](omnibus/files/chef-dk-gem/build-chef-dk-gem.rb#L32-L54).
   - [Runs](omnibus/config/software/chef-dk.rb#L68) `bundle install --verbose`
3. Reinstalls any gems that were installed via path:
   - [Runs](omnibus/files/chef-dk/build-chef-dk.rb#L80) `bundle list --paths` to get the installed directories of all gems.
   - For each gem not installed in the main gem dir, [runs](omnibus/files/chef-dk/build-chef-dk.rb#L89) `rake install` from the installed gem directory.
   - [Deletes](omnibus/files/chef-dk/build-chef-dk.rb#L139-L143) the bundler git cache and path- and git-installed gems from the build.
4. [Creates](omnibus/files/chef-dk/build-chef-dk.rb#L102-L152) `/opt/chefdk/Gemfile` and `/opt/chefdk/Gemfile.lock` with the gems that were installed in the build.

#### Gems and Caching

Some gems take a super long time to install (particularly native-compiled ones such as nokogiri and dep-selector-libgecode) and do not change version very often. In order to avoid doing this work every time, we take advantage of omnibus caching by separating out these gems into their own software definitions. [chef-dk-gem-dep-selector-libgecode](omnibus/config/software/chef-dk-gem-dep-selector-libgecode.rb) for example.

Each of these gems uses the `config/files/chef-dk-gem/build-chef-dk-gem` library to define itself. The name of the software definition itself indicates the .

We only create software definitions for long-running gems. Everything else is just installed in the [chef-dk](omnibus/config/software/chef-dk.rb) software definition in a big `bundle install` catchall.

Most gems we just install in the single `chef-dk` software definition.

The first thing

### Appbundling

After the gems are installed, we *appbundle* them in [chef-dk-appbundle](omnibus/config/software/chef-dk-appbundle.rb). This creates binstubs that use the bundle to pin the software .

During the process of appbundling, we update the gem's `Gemfile` to include the locks in the top level `/opt/chefdk/Gemfile.lock`, so we can guarantee they will never pick up things outside the build. We then run `bundle lock` to update the gem's `Gemfile.lock`, and `bundle check` to ensure all the gems are actually installed. The appbundler then uses these pins.

### Other Cleanup

Finally, the chef-dk does several more steps including installing powershell scripts and shortcuts, and removing extra documentation to keep the build slim.

- - -

[Berkshelf]: http://berkshelf.com "Berkshelf"
[Chef]: https://www.chef.io "Chef"
[ChefDK]: https://downloads.chef.io/chef-dk "Chef Development Kit"
[Chef Documentation]: https://docs.chef.io "Chef Documentation"
[ChefSpec]: http://chefspec.org "ChefSpec"
[Foodcritic]: http://foodcritic.io "Foodcritic"
[Learn Chef]: https://learn.chef.io "Learn Chef"
[Test Kitchen]: http://kitchen.ci "Test Kitchen"
