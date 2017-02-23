# ChefDK 1.3 Release Notes

## Workflow Build Cookbooks
Build cookbooks generated via `chef generate build-cookbook` will no longer depend on the delivery_build or delivery-base cookbook. Instead, the Test Kitchen instance will use ChefDK as per the standard Workflow Runner setup.

Also the build cookbook generator will not overwrite your `config.json` or `project.toml` if they exist already on your project.

## ChefSpec

With the 6.0 release of ChefSpec, rather than creating a ChefZero instance per ServerRunner test context, a single ChefZero instance is created that all ServerRunner test contexts will leverage. The ChefZero instance is reset between each test case, emulating the existing behavior without needing a monotonically increasing number of ChefZero instances.

Additionally, if you are using ChefSpec to test a pre-defined set of Cookbooks, there is now an option to upload those cookbooks only once, rather than before every test case. To take advantage of this performance enhancer, simply set the `server_runner_clear_cookbooks` RSpec configuration value to `false` in your `spec_helper.rb`.

    RSpec.configure do |config|
      config.server_runner_clear_cookbooks = false
    end

Setting this value to `false` has been shown to increase the ServerRunner performance by 75%, improve stability on Windows, and make the ServerRunner as fast as SoloRunner.

Also included are three new matchers: `dnf_package`, `msu_package`, and `cab_package`

## Inspec

 * Better support for querying and filter in the [`processes` resource](http://inspec.io/docs/reference/resources/processes/).
 * New `packages` resource for Debian-based platforms.

## Kitchen EC2 Driver

 * Adds support for Windows 2016 instances
 * [various other improvements](https://github.com/test-kitchen/kitchen-ec2/blob/master/CHANGELOG.md).

## Notable Updated Gems

  * berkshelf 5.6.0 -> 5.6.3
  * chef-provisioning 2.1.0 -> 2.1.1
  * chef-zero 5.2.0 -> 5.3.0
  * cheffish 4.1.0 -> 4.1.1
  * chefspec 5.3.0 -> 6.0.0
  * cookstyle 1.2.0 -> 1.3.0
  * inspec 1.11.0 -> 1.14.1
  * kitchen-dokken 1.1.0 -> 2.1.2
  * kitchen-ec2 1.2.0 -> 1.3.1
  * kitchen-vagrant 1.0.0 -> 1.0.2
  * mixlib-install 2.1.11 -> 2.1.12
  * specinfra 2.66.7 -> 2.67.1
