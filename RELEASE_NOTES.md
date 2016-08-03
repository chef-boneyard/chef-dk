# ChefDK 0.16 Release notes

## Chef Generate Improvements.
* `chef generate cookbook` now automatically creates files for Chef Automate's workflow features.
 * Files are located in `.delivery` folder in the generated cookbook.
* `chef generate cookbook` has improved output formatting.
* `chef generate cookbook` now defaults to creating cookbooks that use Inspec tests by default.
 * Tests are located at `<cookbook>/test/recipes/<recipename>_test.rb`.
 * Tests in existing cookbooks at old location will work fine.

## New `delivery local` command provides a single-command interface to ChefDK.
* Run `delivery local --help` for details.
* Customize `delivery local` behavior with the `.delivery/project.toml` file in your project.

## Cookstyle is now default code linter instead of Rubocop.
* Cookstyle wraps Rubocop, and provides Chef's recommended default set of cops automatically.
* Execute with `delivery local lint` or `chef exec cookstyle`.
* If you prefer, you can continue to use Rubocop directly.

## `kitchen-dokken` driver now included in ChefDK.

## Knife updates.
* `knife cookbook create` and `berks cookbook` commands are deprecated in favor of `chef generate cookbook`.
* knife supermarket gem has been folded directly into knife, and is no longer a separate gem.
* `knife cookbook site` command now behaves as a wrapper to `knife supermarket` command.
