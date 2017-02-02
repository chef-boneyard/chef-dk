# ChefDK 1.2.22 (hotfix) Release Notes

This is a hotfix release to address a security vulnerability exposed through
[mixlib-archive](https://github.com/chef/mixlib-archive) which allowed a berkshelf
or chef install to overwrite local files by giving them a malicious tarball
that was specially crafted.

## Notable Updated Gems
- berkshelf 5.2.0 -> 5.6.0
- cookbook-omnifetch 0.5.0 -> 0.5.1
- foodcritic 8.2.0 -> 9.0.0
- inspec 1.10.0 -> 1.11.0
- knife-windows 1.8.0 -> 1.9.0
- mixlib-archive 0.3.0 -> 0.4.1
- mixlib-install 2.1.10 -> 2.1.11
