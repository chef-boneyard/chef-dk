# ChefDK 1.6 Release Notes

This release of ChefDK contains Ruby 2.3.5, fixing 4 CVEs:
  * CVE-2017-0898
  * CVE-2017-10784
  * CVE-2017-14033
  * CVE-2017-14064

The 2.2.1 release includes RubyGems 2.6.13 to fix the following CVEs:
  * CVE-2017-0899
  * CVE-2017-0900
  * CVE-2017-0901
  * CVE-2017-0902

This release of ChefDK update the embedded git to 2.14.1 to address [CVE-2017-1000117](https://www.cvedetails.com/cve/CVE-2017-1000117/)

This also bumps the Chef version from 12.21.2 to 12.21.4 along with patch bumps to several other gem dependencies.

# ChefDK 1.5 Release Notes

## Security Fixes

This release of Chef Client contains a new version of zlib, fixing 4
CVEs:

 *  [CVE-2016-9840](https://www.cvedetails.com/cve/CVE-2016-9840/)
 *  [CVE-2016-9841](https://www.cvedetails.com/cve/CVE-2016-9841/)
 *  [CVE-2016-9842](https://www.cvedetails.com/cve/CVE-2016-9842/)
 *  [CVE-2016-9843](https://www.cvedetails.com/cve/CVE-2016-9843/)


## Chef 12.21

Chef has been updated to the 12.21 release, fixing a number of bugs:

 * On Debian based systems, correctly prefer Systemd to Upstart
 * Handle the supports pseudo-property more gracefully
 * Don't crash when we downgrade from Chef 13 to Chef 12
 * Provide better system information when Chef crashes

See the [Release Notes](https://github.com/chef/chef/blob/chef-12/RELEASE_NOTES.md) for further information

## Notable Updated Gems

* cookstyle 1.3.1 -> 1.4.0 ([Changelog](https://github.com/chef/cookstyle/blob/master/CHANGELOG.md))

# ChefDK 1.4 Release Notes

## InSpec

InSpec has been updated to 1.25.1 with the following new functionality:

* Consistent hashing for InSpec profiles
* Add platform info to json formatter
* Allow mysql_session to test databases on different hosts
* Add an oracledb_session resource
* Support new Chef Automate compliance backend

Find the full list of changes [here](https://github.com/chef/inspec/blob/master/CHANGELOG.md#v1250-2017-05-17).

## Notable Updated Gems

* cookstyle 1.3.0 -> 1.3.1 ([Changelog](https://github.com/chef/cookstyle/blob/master/CHANGELOG.md))
