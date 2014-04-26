# Chef Development Kit

Chef Development Kit (Chef DK) brings Chef and the development tools developed by the Chef Community together and acts as the consistent interface to this awesomeness. This awesomeness is composed of:

* [Chef](http://www.getchef.com)
* [Berkshelf](http://berkshelf.com)
* [Test Kitchen](http://kitchen.ci)
* [ChefSpec](http://code.sethvargo.com/chefspec/)
* [Foodcritic](http://acrmp.github.io/foodcritic/)

This repository contains the code for the `chef` command. The full
package is built via the 'chefdk' project in
[omnibus-chef.](https://github.com/opscode/omnibus-chef)

## Installation

You can get the latest release of ChefDK from [our downloads page.](http://www.getchef.com/downloads/chef-dk/)

On Mac OS X, you can also use [homebrew-cask](http://caskroom.io)
to install ChefDK.

Once you install the package, the `chef-client` suite, `berks`,
`kitchen` and this application (`chef`) will be symlinked into your
system bin directory, ready to use.

## Usage

For help with Berkshelf, Test Kitchen, ChefSpec or FoodCritic, visit
those projects' homepages for documentation and guides. For help with
`chef-client` and `knife`, visit the [Chef documentation](http://docs.opscode.com)
and [Learn Chef](https://learnchef.opscode.com).

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

#### `chef gem`
`chef gem` is a wrapper command that manages installation and updating
of rubygems for the Ruby installation embedded in the ChefDK package.
This allows you to install knife plugins, Test Kitchen drivers, and
other Ruby applications that are not packaged with ChefDK.

Gems are installed to a `.chefdk` directory in your home directory; any
executables included with a gem you install will be created in
`~/.chefdk/gem/ruby/2.1.0/bin`, so add this to your `PATH` if you plan
to use executables installed this way.

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
environment, however, you can do so by making a few modifications to
your environment:
* Add `/opt/chefdk/embedded/bin` to your `PATH`. This gives you access
to ChefDK's embedded `ruby` and support applications.
* Add `~/.chefdk/gem/ruby/2.1.0/bin` to your `PATH`. This will allow you
to run any command line applications you install via `chef gem`.

