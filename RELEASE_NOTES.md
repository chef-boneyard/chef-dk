# ChefDK 1.0 Release notes

## Version 1.0!
* Recognize ChefDK's continued stability with the honor of a 1.0 tag. There is
nothing in this release that breaks backwards compatibility with previous
installations of ChefDK: it is simply a formal recognition of the stability of
the product.

## Foodcritic
* Foodcritic constraint updated to require v8.0 or greater.
* Supermarket Foodcritic rules are now disabled by default when you run `chef generate cookbook`.

# ChefDK 0.19 Release notes

## InSpec
* InSpec Updated to v1.2.0. See the [InSpec CHANGELOG](https://github.com/chef/inspec/tree/v1.2.0) for details.

## Mixlib::Install
* New `mixlib-install` command allows you to quickly download Chef binaries. Run `mixlib-install help` for command usage.

## Delivery CLI
* Deprecation of Github V1 backed project initialization.
* Initialization of Github V2 backed projects (`delivery init --github`). Requires Chef Automate server version `0.5.432` or above.
* Project name verification with repository name for projects with SCM Integration.
* Increased clarity of the command structure by introducing the `--pipeline` alias for the `--for` option.
* Honor custom config on project initialization (`delivery init -c /my/config.json`).
* Build cookbook is now generated using the more appropriate `chef generate build-cookbook` on project initialization.
* Support providing your password non-interactively to `delivery token` via the `AUTOMATE_PASSWORD` environment variable (`AUTOMATE_PASSWORD=password delivery token`).
