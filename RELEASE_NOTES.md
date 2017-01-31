# ChefDK 1.3 Release Notes

## Workflow Build Cookbooks
Build cookbooks generated via `chef generate build-cookbook` will no longer
depend on the delivery_build or delivery-base cookbook. Instead, the Test
Kitchen instance will use ChefDK as per the standard Workflow Runner setup.
