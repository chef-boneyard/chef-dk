# Building the ChefDK

To build the chef-dk, we use the omnibus system. Go to the
[omnibus README](omnibus/README.md) to find out how to build!

# Installation and Testing

A standard `bundle install` in the root directory and in the `omnibus/`
directory will get you started. You can run unit tests via:

## Unit Testing

```
bundle exec rspec spec/
```

## Chef Verify

You can run the [chef verify command](README.md#chef-verify) on your local dev
environment if you have the ChefDK binary installed. Note that you will likely
need the current version of ChefDK, not the last released version. You can get
the current version [here](http://artifactory.chef.co/simple/omnibus-current-local/com/getchef/chefdk/).

Once installed, you can run the `chef verify` command by pointing at the location
of the root the latest current version on your local disk by running:

```
bin/chef verify git --omnibus-dir <path_to_root_of_current_version>
```

If you used the defaults while installing, `<path_to_root_of_current_version>` is
simply `/opt/chefdk`.

# Updating Dependencies

If you want to change our constraints (change which packages and
versions we accept in the chef-dk), there are several places to do so:

* To add or remove a package from the chef-dk, or update its version,
  edit [Gemfile](Gemfile).
* To change the version of binary packages, edit
  [version_policy.rb](version_policy.rb).
* To add new packages to the chef-dk, edit
  [omnibus/config/projects/chefdk.rb](omnibus/config/projects/chefdk.rb).

Once you've made any changes you want, you have to update the lockfiles
that actually drive the build:

* To update the chef-dk's dependencies to the very latest versions
  available, run `rake bundle:update`.
* To update the chef-dk's dependencies *conservatively* (changing as
  little as possible), run `rake bundle:install`.
* To update specific gems only, run `rake bundle:update[gem1 gem2 ...]`
* **`bundle update` and `bundle install` will *not* work, on purpose:**
  the rake task handles both the windows and non-windows lockfiles and
updates them in sync.

To perform a full update of all dependencies everywhere, run `./ci/dependency_update.sh`.
This will update the `Gemfile.lock`,
`Gemfile.windows.lock`, `omnibus/Gemfile.lock`,
`acceptance/Gemfile.lock`, `omnibus/Berksfile.lock`, and
`omnibus_overrides.rb`.  It will also show you any outdated dependencies
due to conflicting constraints. Some outdated dependencies are to be
expected; it will inform you if any new ones appear that we don't know
about, and tell you how to proceed.

# How the ChefDK Builds and Versions

The ChefDK is an amalgam of many components. These components update all
the time, necessitating new builds. This is an overview of the process
of versioning, building and releasing the ChefDK.

## ChefDK Packages

The ChefDK is distributed as packages for debian, rhel, ubuntu, windows
and os/x. It includes a large number of components from various sources,
and these are versioned and maintained separately from the chef-dk
project, which bundles them all together conveniently for the user.

These packages go through several milestones:
- `master`: When code is checked in to master, the patch version of
  chef-dk is bumped (e.g. 0.9.10 -> 0.9.11) and a build is kicked off
automatically to create and test the packages in Chef's Jenkins cluster.
- `unstable`: When a package is built, it enters the unstable channel.
  When all packages for all OS's have successfully built, the test phase
is kicked off in Jenkins across all supported OS's. These builds are
password-protected and generally only available to the test systems.
- `current`: If the packages pass all the tests on all supported OS's,
  it is promoted as a unit to `current`, and is available via Chef's
artifactory by running `curl https://omnitruck.chef.io/install.sh | sudo
bash -s -- -c current -P chefdk`
- `stable`: Periodically, Chef will pick a release to "bless" for folks
  who would like a slower update schedule than "every time a build
passes the tests." When this happens, it is manually promoted to stable
and an announcement is sent to the list. It can be reached at
https://downloads.chef.io or installed using the `curl` command without
specifying `-c current`. Packages in `stable` are no longer available in
`current`.

Additionally, periodically Chef will update the desired versions of
chef-dk components and check that in to `master`, triggering a new build
with the updated components in it.

## Automated Version Bumping

Whenever a change is checked in to `master`, the patch version of
`chef-dk` is bumped. To do this, the `lita-versioner` bot listens to
github for merged PRs, and when it finds one, takes these actions:

1. Bumps the patch version in `lib/chef-dk/version.rb` (e.g. 0.9.14 ->
   0.9.15).
2. Runs `rake dependencies:update_conservative` to update the
   `Gemfile.lock` and `Gemfile.windows.lock` to include the new version.
3. Pushes to `master` and submits a new build to Chef's Jenkins cluster.

## Component Versions

The chef-dk has two sorts of component: ruby components like `berkshelf`
and `test-kitchen`, and binary components like `openssl` and even `ruby`
itself.

In general, you can find all chef-dk desired versions in the
[Gemfile](Gemfile) and [version_policy.rb](version_policy.rb) files. The
[Gemfile.lock](Gemfile.lock) is the locked version of the Gemfile, and
[omnibus_overrides](omnibus_overrides.rb) is the locked version of
omnibus. [build](omnibus/Gemfile) and [test](acceptance/Gemfile)
Gemfiles and [Berksfile](omnibus/Berksfile) version the toolset we use
to build and test.

### Binary Components

The versions of binary components (as well as rubygems and bundler,
which can't be versioned in a Gemfile) are stored in
[version_policy.rb](version_policy.rb) (the `OMNIBUS_OVERRIDES`
constant) and locked in [omnibus_overrides](omnibus_overrides.rb).
`rake dependencies` will update the `bundler` version, and the rest are
be updated manually by Chef every so often.

These have software definitions either in
[omnibus/config/software](omnibus/config/software) or, more often, in
the
[omnibus-software](https://github.com/chef/omnibus-software/tree/master/config/software)
project.

### Rubygems Components

Most of the actual front-facing software in the chef-dk is composed of
ruby projects. berkshelf, test-kitchen and even chef itself are made of
ruby gems. Chef uses the typical ruby way of controlling rubygems
versions, the `Gemfile`. Specifically, the `Gemfile` at the top of the
chef-dk repository governs the version of every single gem we install
into the chef-dk package. It's a one-stop shop.

Our rubygems component versions are locked down with `Gemfile.lock` and
`Gemfile.windows.lock` (which affects windows), and can be updated with
`rake dependencies`.

There are three gems versioned outside the `Gemfile`: `rubygems`,
`bundler` and `chef`. `rubygems` and `bundler` are in the
`RUBYGEMS_AT_LATEST_VERSION` constant in
[version_policy.rb](version-policy.rb) and locked in
[omnibus_overrides](omnibus_overrides.rb). `chef`'s version is stored in
the [Gemfile](Gemfile) and pins to the latest `current` build of chef
(the latest one to pass tests). They are kept up to date by `rake
dependencies`.

**Windows**: [Gemfile.lock](Gemfile.lock) is generated
platform-agnostic. In order to keep windows versions in sync,
[Gemfile.windows](Gemfile.windows) reads the generic Gemfile.lock and
explicitly pins all gems to those versions, allowing bundler to bring in
windows-specific versions of the gems and new deps, but requiring that
all gems shared between Windows and Unix have the same version.

The tool we use to generate Windows-specific lockfiles on non-Windows
machines is [tasks/bin/bundle-platform](bundle-platform), which takes
the first argument and sets `Gem.platforms`, and then calls `bundle`
with the remaining arguments.

### Build Tooling Versions

Of special mention is the software we use to build omnibus itself. There
are two distinct bits of code that control the versions of compilers,
make, git, and other tools we use to build.

First, the Jenkins machines that run the build are configured entirely
by the [opscode-ci cookbook](https://github.com/chef-cookbooks/opscode-ci)
cookbook. They install most of the tools we use via `build-essentials`,
and standardize the build environment so we can tear down and bring up
builders at will.  These machines are kept alive long-running, are
periodically updated by Chef to the latest opscode-ci, omnibus and
build-essentials cookbooks.

Second, the version of omnibus we use to build the chef-dk is governed
by `omnibus/Gemfile`. When software definitions or the omnibus framework
is updated, this is the file that drives whether we pick it up.

The omnibus tooling versions are locked down with
`omnibus/Gemfile.lock`, and can be updated by running `rake
dependencies`.

### Test Versions

chef-dk is tested by the [chef-acceptance framework](https://github.com/chef/chef-acceptance),
which contains suites that are run on the Jenkins test machines. The
definitions of the tests are in the `acceptance` directory. The version
of chef-acceptance and test-kitchen, are governed by
`acceptance/Gemfile`.

The test tooling versions are locked down with
`acceptance/Gemfile.lock`, which can be updated by running `rake
dependencies`.

## The Build Process

The actual ChefDK build process is done with Omnibus, and has several
general steps:

1. `bundle install` from `chef-dk/Gemfile.lock`
2. Reinstall any gems that came from git or path using `rake install`
3. appbundle chef, chef-dk, test-kitchen and berkshelf
4. Put miscellaneous powershell scripts and cleanup

### Kicking Off The Build

The build is kicked off in Jenkins by running this on the machine (which
is already the correct OS and already has the correct dependencies,
loaded by the `omnibus` cookbook):

```
load-omnibus-toolchain.bat
cd chef-dk/omnibus
bundle install
bundle exec omnibus build chefdk
```

This causes the [chefdk project definition](omnibus/config/projects/chefdk.rb)
to load, which runs the
[chef-dk-complete](omnibus/config/software/chef-dk-complete.rb) software
definition, the primary software definition driving the whole build
process. The reason we embed it all in a software definiton instead of
the project is to take advantage of omnibus caching: omnibus will
invalidate the entire project (and recompile ruby, openssl, and
everything else) if you change anything at all in the project file. Not
so with a software definition.

### Installing the Gems

The primary build definition that installs the many ChefDK rubygems is
[`software/chef-dk.rb`](omnibus/software/chef-dk.rb). This has
dependencies on any binary libraries, ruby, rubygems and bundler. It has
a lot of steps, so it uses a
[library](omnibus/files/chef-dk/build-chef-dk.rb) to help reuse code and
make it manageable to look at.

What it does:

1. Depends on software defs for pre-cached gems (see "Gems and Caching"
   below).
2. Installs all gems from the bundle:
   - Sets up a `.bundle/config`
     ([code](omnibus/files/chef-dk/build-chef-dk.rb#L17-L39)) with
     --retries=4, --jobs=1, --without=development,no_<platform>, and
     `build.config.nokogiri` to pass.
   - Sets up a common environment, standardizing the compilers and flags
     we use, in [`env`](omnibus/files/chef-dk-gem/build-chef-dk-gem.rb#L32-L54).
   - [Runs](omnibus/config/software/chef-dk.rb#L68) `bundle install --verbose`
3. Reinstalls any gems that were installed via path:
   - [Runs](omnibus/files/chef-dk/build-chef-dk.rb#L80) `bundle list --paths`
     to get the installed directories of all gems.
   - For each gem not installed in the main gem dir,
     [runs](omnibus/files/chef-dk/build-chef-dk.rb#L89) `rake install`
from the installed gem directory.
   - [Deletes](omnibus/files/chef-dk/build-chef-dk.rb#L139-L143) the
     bundler git cache and path- and git-installed gems from the build.
4. [Creates](omnibus/files/chef-dk/build-chef-dk.rb#L102-L152)
   `/opt/chefdk/Gemfile` and `/opt/chefdk/Gemfile.lock` with the gems that
   were installed in the build.

#### Gems and Caching

Some gems take a super long time to install (particularly
native-compiled ones such as nokogiri and dep-selector-libgecode) and do
not change version very often. In order to avoid doing this work every
time, we take advantage of omnibus caching by separating out these gems
into their own software definitions.
[chef-dk-gem-dep-selector-libgecode](omnibus/config/software/chef-dk-gem-dep-selector-libgecode.rb)
for example.

Each of these gems uses the `config/files/chef-dk-gem/build-chef-dk-gem`
library to define itself. The name of the software definition itself
indicates the .

We only create software definitions for long-running gems. Everything
else is just installed in the
[chef-dk](omnibus/config/software/chef-dk.rb) software definition in a
big `bundle install` catchall.

Most gems we just install in the single `chef-dk` software definition.

The first thing

### Appbundling

After the gems are installed, we *appbundle* them in
[chef-dk-appbundle](omnibus/config/software/chef-dk-appbundle.rb). This
creates binstubs that use the bundle to pin the software .

During the process of appbundling, we update the gem's `Gemfile` to
include the locks in the top level `/opt/chefdk/Gemfile.lock`, so we can
guarantee they will never pick up things outside the build. We then run
`bundle lock` to update the gem's `Gemfile.lock`, and `bundle check` to
ensure all the gems are actually installed. The appbundler then uses
these pins.

### Other Cleanup

Finally, the chef-dk does several more steps including installing
powershell scripts and shortcuts, and removing extra documentation to
keep the build slim.
