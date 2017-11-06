# ChefDK 2.4 Release Notes

## Improved Performance Downloading Cookbooks from a Chef Server

Policyfile users who use a Chef Server as a cookbook source will
experience faster cookbook downloads when running `chef install`. Chef
Server's API requires each file in a cookbook to be downloaded
separately; ChefDK will now download the files in parallel.
Additionally, HTTP keepalives are enabled to reduce connection overhead.

## Cookbook Artifact Source for Policyfiles

Policyfile users may now source cookbooks from the Chef Server's
cookbook artifact store. This is mainly intended to support the upcoming
`include_policy` feature, but could be useful in some situations.

Given a cookbook that has been uploaded to the Chef Server via `chef push`,
it can be used in another policy by adding code like the following to
the ruby policyfile:

```
cookbook "runit",
  chef_server_artifact: "https://chef.example/organizations/myorg",
  identifier: "09d43fad354b3efcc5b5836fef5137131f60f974"
```

# ChefDK 2.3 Release Notes

ChefDK 2.3 includes Ruby 2.4.2 to fix the following CVEs:
  * CVE-2017-0898
  * CVE-2017-10784
  * CVE-2017-14033
  * CVE-2017-14064

The 2.2.1 release includes RubyGems 2.6.13 to fix the following CVEs:
  * CVE-2017-0899
  * CVE-2017-0900
  * CVE-2017-0901
  * CVE-2017-0902

ChefDK 2.3 includes:
  * Chef 13.4.19
  * InSpec 1.36.1
  * Berkshelf 6.3.1
  * Chef Vault 3.3.0
  * Foodcritic 11.4.0
  * Test Kitchen 1.17.0
  * Stove 6.0

## Stove is now included

We are now shipping stove in ChefDK, to aid users in uploading their
cookbooks to supermarkets.

## The cookbook generator now adds a LICENSE file

The cookbook generator now adds a LICENSE file when creating a new
cookbook.


## Boilerplate tests are generated for the CentOS platform
When `chef generate cookbook` is ran, boilerplate unit tests for the CentOS 7 platform are now generated as well.
