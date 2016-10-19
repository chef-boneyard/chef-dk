# ChefDK 0.19 Release notes

## Inspec
* InSpec Updated to v1.2.0. See the [InSpec CHANGELOG](https://github.com/chef/inspec/tree/v1.2.0) for details.

## delivery-cli
* Deprecation of Github V1 Backed Project Initialization.
* Initialization of Github V2 Backed Projects (`delivery init --github`). (Requires Automate Server version `0.5.432` or above)
* Project name verification with repository name for projects with SCM Integration.
* New alias `--pipeline` for option `--for`.
* Honor the custom config on project initialization. (`delivery init -c /my/config.json`)
* Generate build-cookbook with chefdk build-cookbook command on project initialization.
 
