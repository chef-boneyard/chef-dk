# ChefDK 1.2 Release Notes

- Updated the project.toml file generator with:
  - A `functional` phase that will be optional for implementation.
  - New `remote_file` option to specify a remote project.toml.
- Bundle the Stunnel tool and FIPS OpenSSL module for users who need to enforce FIPS compliance.

- Add Chef Server policyfile resolution.
  - Adds a `chef_server` default source option to Policyfiles

### delivery-cli Changes

- New `remote_file` option to load `project.toml` from URL.
- Added the `functional` phase for the `delivery local` command.
- Fix that will update the remote of projects based on relevant `cli.toml` or settings passed through the command-line.
- Honor project name from project config (`cli.toml`) or options provided through the command-line.
- Added FIPS options to `cli.toml` to communicate to Automate Server when FIPS mode is enabled.
