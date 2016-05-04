# ChefDK 0.14 Release notes

## New tools added to the ChefDK

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

