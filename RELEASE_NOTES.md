# ChefDK 0.19 Release notes

## Inspec
* InSpec Updated to v1.2.0. See the [InSpec CHANGELOG](https://github.com/chef/inspec/tree/v1.2.0) for details.

## delivery-cli
* Deprecation of Github V1 backed project initialization.
* Initialization of Github V2 backed projects (`delivery init --github`). Requires Chef Automate server version `0.5.432` or above.
* Project name verification with repository name for projects with SCM Integration.
* New alias `--pipeline` for option `--for`.
* Honor the custom config on project initialization (`delivery init -c /my/config.json`).
* Generate build-cookbook with `chef generate build-cookbook` command on project initialization.
 
