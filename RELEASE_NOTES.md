# ChefDK 1.3 Release Notes

## Workflow Build Cookbooks
Build cookbooks generated via `chef generate build-cookbook` will no longer
depend on the delivery_build or delivery-base cookbook. Instead, the Test
Kitchen instance will use ChefDK as per the standard Workflow Runner setup.

Also the build cookbook generator will not overwrite your `config.json` or
`project.toml` if they exist already on your project.

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
