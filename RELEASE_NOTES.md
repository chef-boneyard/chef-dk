# ChefDK 0.15 Release notes

## Improved generator support for delivery

We have added a bit of added functionality around the generators to better support delivery users:

* New option `-d/--delivery` to `chef generate cookbook`, which will create a `.delivery/config.json` and build cookbook in the generated cookbook.
* New generator subcommand, `chef generate build-cookbook`, which creates the `.delivery` content as above, but outside the context of generating a new cookbook. This includes the same auto-detection logic as Pipeline Build Cookbook to determine if the project is a cookbook or not, and modify the generated content accordingly.
