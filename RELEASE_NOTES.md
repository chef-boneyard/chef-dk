# ChefDK 1.4 Release Notes

## Security Fixes

This release of Chef Client contains a new version of zlib, fixing 4
CVEs:

 *  [CVE-2016-9840](https://www.cvedetails.com/cve/CVE-2016-9840/)
 *  [CVE-2016-9841](https://www.cvedetails.com/cve/CVE-2016-9841/)
 *  [CVE-2016-9842](https://www.cvedetails.com/cve/CVE-2016-9842/)
 *  [CVE-2016-9843](https://www.cvedetails.com/cve/CVE-2016-9843/)

## InSpec

InSpec has been updated to 1.25.1 with the following new functionality:

* Consistent hashing for InSpec profiles
* Add platform info to json formatter
* Allow mysql_session to test databases on different hosts
* Add an oracledb_session resource
* Support new Chef Automate compliance backend

Find the full list of changes [here](https://github.com/chef/inspec/blob/master/CHANGELOG.md#v1250-2017-05-17).

## Notable Updated Gems

* cookstyle 1.3.0 -> 1.3.1 ([Changelog](https://github.com/chef/cookstyle/blob/master/CHANGELOG.md))
