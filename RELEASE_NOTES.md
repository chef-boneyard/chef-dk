# ChefDK 1.3 Release Notes

## Note

There is a known issue on the Windows platform that prevents FIPS usage. If this would affect you, please continue to use ChefDK 1.2.22 until we resolve this issue with a patch release.

## Chef Client 12.19

ChefDK now ships with Chef 12.19\. Check out <https://docs.chef.io/release_notes.html> for all the details of this new release.

## Workflow Build Cookbooks

Build cookbooks generated via `chef generate build-cookbook` will no longer depend on the delivery_build or delivery-base cookbook. Instead, the Test Kitchen instance will use ChefDK as per the standard Workflow Runner setup.

Also the build cookbook generator will not overwrite your `config.json` or `project.toml` if they exist already on your project.

## ChefSpec 6.0

ChefDK includes the new ChefSpec 6.0 release with improvements to the ServerRunner behavior. Rather than creating a ChefZero instance per ServerRunner test context, a single ChefZero instance is created that all ServerRunner test contexts will leverage. The ChefZero instance is reset between each test case, emulating the existing behavior without needing a monotonically increasing number of ChefZero instances.

Additionally, if you are using ChefSpec to test a pre-defined set of Cookbooks, there is now an option to upload those cookbooks only once, rather than before every test case. To take advantage of this performance enhancer, simply set the `server_runner_clear_cookbooks` RSpec configuration value to `false` in your `spec_helper.rb`.

```
RSpec.configure do |config|
  config.server_runner_clear_cookbooks = false
end
```

Setting this value to `false` has been shown to increase the ServerRunner performance by 75%, improve stability on Windows, and make the ServerRunner as fast as SoloRunner.

This new release also includes three new matchers: `dnf_package`, `msu_package`, and `cab_package` and utilizes the new Fauxhai 4.0 release. This includes several new platforms and removes many older end of life platforms. See <https://github.com/customink/fauxhai/blob/master/PLATFORMS.md> for a list of all supported platforms for use in ChefSpec.

## InSpec

InSpec has been updated to 1.19.1 with the following new functionality:

- Better filter support for the [`processes` resource](http://inspec.io/docs/reference/resources/processes/).
- New `packages`, `crontab`, `x509_certificate`, and `x509_private_key` resources
- New `inspec habitat profile create` command to create a Habitat artifact for a given InSpec profile.
- Functional JUnit reporting
- A new command for generating profiles has been added

## Foodcritic

Foodcritic has been updated to 10.2.2\. This release includes the following new functionality

- FC003, which required gating certain code when running on Chef Solo has been removed
- FC023, which preferred conditional (only_if / not_if) code within resources has been removed as many disagreed with this coding style
- False positives in FC007 and FC016 have been resolved
- New rules have been added requiring the license (FC068), supports (FC067), and chef_version (FC066) metadata properties in cookbooks

## Kitchen EC2 Driver

Kitchen-ec2 has been updated to 1.3.2 with support for Windows 2016 instances

## Notable Updated Gems

- berkshelf 5.6.0 -> 5.6.4 ([Changelog](https://github.com/berkshelf/berkshelf/blob/master/CHANGELOG.md))
- chef-provisioning 2.1.0 -> 2.2.1 ([Changelog](https://github.com/chef/chef-provisioning/blob/master/CHANGELOG.md))
- chef-provisioning-aws 2.1.0 -> 2.2.0 ([Changelog](https://github.com/chef/chef-provisioning-aws/blob/master/CHANGELOG.md))
- chef-zero 5.2.0 -> 5.3.1 ([Changelog](https://github.com/chef/chef-zero/blob/master/CHANGELOG.md))
- chef 12.18.31 -> 12.19.36 ([Changelog](https://github.com/chef/chef/blob/master/CHANGELOG.md))
- cheffish 4.1.0 -> 5.0.1 ([Changelog](https://github.com/chef/cheffish/blob/master/CHANGELOG.md))
- chefspec 5.3.0 -> 6.2.0 ([Changelog](https://github.com/sethvargo/chefspec/blob/master/CHANGELOG.md))
- cookstyle 1.2.0 -> 1.3.0 ([Changelog](https://github.com/chef/cookstyle/blob/master/CHANGELOG.md))
- fauxhai 3.10.0 -> 4.1.0 ([Changelog](https://github.com/customink/fauxhai/blob/master/CHANGELOG.md)
- foodcritic 9.0.0 -> 10.2.2 ([Changelog](https://github.com/acrmp/foodcritic/blob/master/CHANGELOG.md)
- inspec 1.11.0 -> 1.19.1 ([Changelog](https://github.com/chef/inspec/blob/master/CHANGELOG.md))
- kitchen-dokken 1.1.0 -> 2.1.2 ([Changelog](https://github.com/someara/kitchen-dokken/blob/master/CHANGELOG.md))
- kitchen-ec2 1.2.0 -> 1.3.2 ([Changelog](https://github.com/test-kitchen/kitchen-ec2/blob/master/CHANGELOG.md))
- kitchen-vagrant 1.0.0 -> 1.0.2 ([Changelog](https://github.com/test-kitchen/kitchen-vagrant/blob/master/CHANGELOG.md))
- mixlib-install 2.1.11 -> 2.1.12 ([Changelog](https://github.com/chef/mixlib-install/blob/master/CHANGELOG.md))
- opscode-pushy-client 2.1.2 -> 2.2.0 ([Changelog](https://github.com/chef/opscode-pushy-client/blob/master/CHANGELOG.md))
- specinfra 2.66.7 -> 2.67.7
- test-kitchen 1.15.0 -> 1.16.0 ([Changelog](https://github.com/test-kitchen/test-kitchen/blob/master/CHANGELOG.md))
- train 0.22.1 -> 0.23.0 ([Changelog](https://github.com/chef/train/blob/master/CHANGELOG.md))
