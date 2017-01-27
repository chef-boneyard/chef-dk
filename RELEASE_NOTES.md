# ChefDK 1.2 Release Notes

## `delivery` CLI
- The `project.toml` file, which can be used to execute [local phases](https://docs.chef.io/ctl_delivery.html#delivery-local), now supports:
  - An optional `functional` phase.
  - New `remote_file` option to specify a remote project.toml.
  - The ability to run stages (collection of phases).
- Fixed bug where the generated `project.toml` file didn't include the prefix `chef exec` for some phases.
- Project git remotes will now be updated automatically, if applicable, based on the values in the `cli.toml` or options provided through the command-line.
- Project names specified in project config (`cli.toml`) or options provided through the command-line will now be honored.

## Policyfiles
- Added a `chef_server` default source option to [Policyfiles](https://docs.chef.io/config_rb_policyfile.html#settings).

## [Workflow] Adopt new job dispatch system on cookbook generation
The `chef generate cookbook` command now defaults to using the configuration for the new job
dispatch system that replaces the previous push jobs based implementation with the SSH based
implementation. For more details on this new system and how to use it, see:
https://docs.chef.io/job_dispatch.html

## FIPS (Windows and RHEL only)
- ChefDK now comes bundled with the Stunnel tool and the FIPS OpenSSL module for users who need to enforce FIPS compliance.
- Support for FIPS options in `delivery` CLI's `cli.toml` were added to handle communication with the Automate Server when FIPS mode is enabled.

## Notable Updated Gems
- berkshelf 5.2.0 -> 5.5.0
- chef 12.17.44 -> 12.18.31
- chef-provisioning 2.0.2 -> 2.1.0
- chef-vault 2.9.0 -> 2.9.1
- chef-zero 5.1.0 -> 5.2.0
- cheffish 4.0.0 -> 4.1.0
- cookstyle 1.1.0 -> 1.2.0
- foodcritic 8.1.0 -> 8.2.0
- inspec 1.7.2 -> 1.10.0
- kitchen-dokken 1.0.9 -> 1.1.0
- kitchen-vagrant 0.21.1 -> 1.0.0
- knife-windows 1.7.1 -> 1.8.0
- mixlib-install 2.1.9 -> 2.1.10
- ohai 8.22.1 -> 8.23.0
- test-kitchen 1.14.2 -> 1.15.0
- train 0.22.0 -> 0.22.1
- winrm 2.1.0 -> 2.1.2
