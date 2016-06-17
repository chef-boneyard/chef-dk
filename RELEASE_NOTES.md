# ChefDK 0.15 Release notes

## Improved generator functionality

* `chef generate cookbook` will commit files to master when it detects that you want it to initialize a new git repo

We are also adding added functionality around the generators to better support delivery users in the future:

* New option `-d/--delivery` to `chef generate cookbook`, which will create a `.delivery/config.json` and build cookbook in the generated cookbook. The `config.json` and the build cookbook will be commited separately to their own feature branch, merged (with `--no-ff` to force a merge commit), and then cleaned up.
* New generator subcommand, `chef generate build-cookbook`, which creates the `.delivery` content as above, but outside the context of generating a new cookbook. This includes the same auto-detection logic as Pipeline Build Cookbook to determine if the project is a cookbook or not, and modify the generated content accordingly.

While these are available in this release, delivery users are advised to continue using `delivery init` instead of the above `chef generate` commands until we release corresponding fixes to the delivery-cli.