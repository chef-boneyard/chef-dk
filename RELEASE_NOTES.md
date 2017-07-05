# Chef DK 2.0

Chef DK 2.0 contains Chef Client 13.2, and is the best way to develop, validate, and deploy Chef cookbooks. We've included the most up to date versions of our toolchain, and have made it easier than ever to build custom resources.
 
Some of the Chef DK 2 highlights include:
 
# Chef Client 13.2
Chef Client 13 is the most delightful version of Chef Client available. We've taken what we've learned from many bug reports, forum posts, and conversations with our users, and made it safer and easier than ever to write great cookbooks. We've included a number of new resources that mean our most popular operating systems are better supported out of the box, and we've made it easier to write patterns that result in reusable, efficient code.
 
Chef Client 13.2 solves a number of issues that were reported in our initial releases of Chef Client 13, and we regard it as suitable for general use.
 
# Policyfiles
It's now possible to update a single cookbook, using `chef update <cookbook>`.
We also support Artifactory as a cookbook source.

# Cookbook Generators

  * Adds `chef generate helpers HELPERS_NAME` to generate a helpers file in libraries

# Berkshelf 6.2.0

Berkshelf adds support for two new sources:
  * Artifactory: `source artifactory: 'https://myserver/api/chef/chef-virtual'` 
  * Chef Repo: `source chef_repo: '.'`
 
# Chef Vault 3.1
Chef Vault 3.1 includes a number of optimizations and speed ups for large numbers of nodes. In most situations, we've seen at least 50% faster creation, update, and refresh operations, and much more efficient memory usage. We've also added a new "sparse" mode, which dramatically reduces the amount of network traffic that occurs as nodes decrypt vaults. A lot of the scalability work has been built and tested by our friends at Criteo.
 
Chef Vault 3.1 also makes it much easier to use provisioning nodes to manage vaults by using the public_key_read_access group, which is available in Chef server 12.5 onwards.
 
# Foodcritic 11
Foodcritic 11 covers many of the patterns we removed in Chef Client 13, so you'll get up-front notification that your cookbooks will no longer work with this release. In general, those patterns  enabled dangerous ways of writing cookbooks.  Ensuring you're compliant with Foodcritic 11 means your cookbooks are safer with every version of Chef.
 
The release of Foodcritic 11 also marks the creation of the Foodcritic org on GitHub, which makes it easier to get involved with writing rules and contributing code. We are excited to start building more of a community around contributing rules for Foodcritic, and can’t wait to see what the community cooks up.
 
# InSpec 1.30
Since the last release of ChefDK, InSpec has been independently released multiple times with a number of great enhancements including some new resources (rabbitmq_config, docker, docker_image, docker_container, oracledb_session), some enhancements to the Habitat package creator for InSpec profiles, and a whole slew of bug fixes and documentation updates.
 
# ChefSpec 7.1.0
It's no longer necessary to create custom matchers; ChefSpec will automatically create matchers for any resources in the cookbooks under test.
 
# Cookstyle 2.0
Cookstyle 2.0 is based on Rubocop 0.49.1, which changed a large number of rule names. 
