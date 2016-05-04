# ChefDK 0.14 Release notes

## New tools added to ChefDK

We're adding some additional tools to the ChefDK to make it easier for cookbook developers using Delivery. The tools are:

* Delivery CLI
* Git
* Push Jobs client
* The following gems:
  * [Chef Sugar](https://github.com/sethvargo/chef-sugar)
  * [Knife Supermarket](https://github.com/chef/knife-supermarket)
  * [Artifactory](https://github.com/chef/artifactory-client)
  * [Mixlib Versioning](https://github.com/chef/mixlib-versioning)

Because existing users may have a `git` client setup we do not put our
bundled `git` executable on the path for most operating systems. Windows
users commonly request that we include `git` so we _are_ adding our
bundled executable to the path. There is an install-time flag you can
use to disable this. If you run `chef shell-init` it will add our
bundled `git` executable to your path.

## `cookstyle` added to ChefDK

`cookstyle` is a linting tool based on rubocop. We created `cookstyle`
to address two issues with rubocop:

1. New releases of rubocop usually contain new style rules, which causes
   most projects to fail style checks after updating rubocop.
2. rubocop's default configuration enables many checks which are not
   appropriate for cookbook development.

`cookstyle` fixes these by pinning to an exact version of rubocop and
replacing the default configuration with one that we've customized to
work better for cookbook development. When a new version of rubocop is
released, we run an automated process to disable new style rules in the
default configuration, which allows you to update with confidence.

In the future, we plan to version cookstyle's ruleset so we can deliver
updates but give you control over when changes take place.

If you have any suggestions for changes to the default ruleset in
`cookstyle`, please [create a pull request](https://github.com/chef/cookstyle).

For more information about `cookstyle`, [see the README on github](https://github.com/chef/cookstyle).

