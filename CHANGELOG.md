<!-- latest_release -->
<!-- latest_release -->

<!-- release_rollup -->
<!-- release_rollup -->

<!-- latest_stable_release -->
<!-- latest_stable_release -->

## [v2.0.28](https://github.com/chef/chef-dk/tree/v2.0.28) (2017-07-14)
[Full Changelog](https://github.com/chef/chef-dk/compare/v2.0.26...v2.0.28)

**Fixed bugs:**

- `chef push` Broken in ChefDK 2.0.26 [\#1322](https://github.com/chef/chef-dk/issues/1322)

## [v1.2.20](https://github.com/chef/chef-dk/tree/v1.2.20) (2017-01-27)
[Full Changelog](https://github.com/chef/chef-dk/compare/v1.1.16...v1.2.20)

**Implemented enhancements:**

- Update Inspec to 1.10.0 \(adds HTTP resource request\) [\#1142](https://github.com/chef/chef-dk/pull/1142) ([tduffield](https://github.com/tduffield))
- Update Chef to 12.18.31 [\#1137](https://github.com/chef/chef-dk/pull/1137) ([tduffield](https://github.com/tduffield))
- Ensure rake is installed via the CI tools [\#1132](https://github.com/chef/chef-dk/pull/1132) ([tduffield](https://github.com/tduffield))
- Add new options to project.toml generator [\#1127](https://github.com/chef/chef-dk/pull/1127) ([afiune](https://github.com/afiune))
- Add in rhel and windows FIPS override [\#1124](https://github.com/chef/chef-dk/pull/1124) ([rmoshier](https://github.com/rmoshier))
- Document chefignore [\#1110](https://github.com/chef/chef-dk/pull/1110) ([vinyar](https://github.com/vinyar))
- Adding maintainer and email fields to example [\#1107](https://github.com/chef/chef-dk/pull/1107) ([jjasghar](https://github.com/jjasghar))
- Accept foo.lock.json as well as foo.rb when loading a policyfile [\#1087](https://github.com/chef/chef-dk/pull/1087) ([mivok](https://github.com/mivok))

**Fixed bugs:**

- Fix `delivery local` failures by adding 'chef exec' prefix to all commands in project.toml [\#1145](https://github.com/chef/chef-dk/pull/1145) ([afiune](https://github.com/afiune))

## [v1.1.16](https://github.com/chef/chef-dk/tree/v1.1.16) (2016-12-14)
[Full Changelog](https://github.com/chef/chef-dk/compare/v1.0.3...v1.1.16)

**Implemented enhancements:**

- Update cookstyle and knife-spork to the latest versions [\#1113](https://github.com/chef/chef-dk/pull/1113) ([afiune](https://github.com/afiune))
- Include Chef 12.17.44 [\#1111](https://github.com/chef/chef-dk/pull/1111) ([tas50](https://github.com/tas50))
- Update gems to get test-kitchen 1.4.2 [\#1109](https://github.com/chef/chef-dk/pull/1109) ([afiune](https://github.com/afiune))
- kitchen-dokken: Default to official `chef/chef` image [\#1103](https://github.com/chef/chef-dk/pull/1103) ([tduffield](https://github.com/tduffield))
- Use 8.22.1 of Ohai [\#1102](https://github.com/chef/chef-dk/pull/1102) ([tduffield](https://github.com/tduffield))
- Add `dco` command line utility to easier management of DCO sign-offs [\#1093](https://github.com/chef/chef-dk/pull/1093) ([tduffield](https://github.com/tduffield))

**Fixed bugs:**

- chef: Use `test/smoke/default` instead of `test/recipes` for generated cookbooks/recipes [\#1096](https://github.com/chef/chef-dk/pull/1096) ([tduffield](https://github.com/tduffield))

## [v1.0.3](https://github.com/chef/chef-dk/tree/v1.0.3) (2016-11-14)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.19.6...v1.0.3)

**Implemented enhancements:**

- chef: Expose `inspec` binary in ChefDK PATH [\#1074](https://github.com/chef/chef-dk/pull/1074) ([schisamo](https://github.com/schisamo))
- knife: Distribute `knife-opc` with ChefDK [\#1072](https://github.com/chef/chef-dk/pull/1072) ([srenatus](https://github.com/srenatus))
- gems: Update mixlib-install to 2.1.6 and berkshelf to 5.2.0 [\#1066](https://github.com/chef/chef-dk/pull/1066) ([schisamo](https://github.com/schisamo))
- gems: Include foodcritic 8 [\#1063](https://github.com/chef/chef-dk/pull/1063) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- windows: Correctly find Git installation included with ChefDK [\#1060](https://github.com/chef/chef-dk/pull/1060) ([scottopherson](https://github.com/scottopherson))

## [v0.19.6](https://github.com/chef/chef-dk/tree/v0.18.30) (2016-10-17)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.18.30...v0.19.6)

**Implemented enhancements:**

- Set the always\_update\_cookbooks flag by default. [\#988](https://github.com/chef/chef-dk/pull/988) ([coderanger](https://github.com/coderanger))

## [v0.18.30](https://github.com/chef/chef-dk/tree/v0.18.30) (2016-09-28)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.18.26...v0.18.30)

**Implemented enhancements:**

- updating inspec and kitchen [\#1030](https://github.com/chef/chef-dk/pull/1030) ([mwrock](https://github.com/mwrock))

## [v0.18.26](https://github.com/chef/chef-dk/tree/v0.18.26) (2016-09-22)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.17.17...v0.18.26)

**Implemented enhancements:**

- Added option --for to build\_cookbook generator to use branch other than master [\#1013](https://github.com/chef/chef-dk/pull/1013) ([Sgtpluck](https://github.com/Sgtpluck))
- Warn instead of erroring when generating a cookbook with a hyphen in the name. [\#955](https://github.com/chef/chef-dk/pull/955) ([tonyflint](https://github.com/tonyflint))
- Upgrade to Ruby 2.3.1 [\#980](https://github.com/chef/chef-dk/pull/980) ([jkeiser](https://github.com/jkeiser))

## [v0.17.17](https://github.com/chef/chef-dk/tree/v0.17.17) (2016-08-15)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.17.14...v0.17.17)

**Implemented enhancements:**

- Bump test-kitchen to 1.11.1. [\#976](https://github.com/chef/chef-dk/pull/976) ([mwrock](https://github.com/mwrock))

## [v0.17.14](https://github.com/chef/chef-dk/tree/v0.17.14) (2016-08-12)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.16.28...v0.17.14)

**Implemented enhancements:**

- Add .kitchen.yml to find generated inspec tests. [\#971](https://github.com/chef/chef-dk/pull/971) ([jkeiser](https://github.com/jkeiser))

## [v0.16.28](https://github.com/chef/chef-dk/tree/v0.16.28) (2016-07-15)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.15.15...v0.16.28)

**Implemented enhancements:**

- Do not allow hyphenated cookbook names to be generated [\#915](https://github.com/chef/chef-dk/pull/915)
- ChefDK generate should use InSpec as default [\#834](https://github.com/chef/chef-dk/issues/834)
- Include knife-supermarket [\#652](https://github.com/chef/chef-dk/issues/652)
- feature request: common kitchen cloud plugin gems should be included in the DK [\#651](https://github.com/chef/chef-dk/issues/651)
- chef provision should use cookbook from ./cookbooks [\#397](https://github.com/chef/chef-dk/issues/397)
- Add support for chef-provisioning-docker [\#329](https://github.com/chef/chef-dk/issues/329)
- Policyfile.rb Chef local mode [\#193](https://github.com/chef/chef-dk/issues/193)
- Update generators for improved file specificity system [\#183](https://github.com/chef/chef-dk/issues/183)
- Add support for kitchen-docker [\#108](https://github.com/chef/chef-dk/issues/108)
- Implement chef test unit command that can run ChefSpec [\#18](https://github.com/chef/chef-dk/issues/18)

**Fixed bugs:**

- chefdk 0.10.0 emits a warning when loading berks [\#597](https://github.com/chef/chef-dk/issues/597)
- OSX ruby executable has an invalid signature [\#258](https://github.com/chef/chef-dk/issues/258)
- Deprecations in chefspec cause updated cookbooks to fail chef spec runs. [\#194](https://github.com/chef/chef-dk/issues/194)
- Deprecations in chefspec cause updated cookbooks to fail chef spec runs. [\#194](https://github.com/chef/chef-dk/issues/194)
- Include chef-zero binary in Chef DK by appbundling it [\#184](https://github.com/chef/chef-dk/issues/184)
- With 'chef generate app', kitchen doesn't seem to find metada.rb [\#50](https://github.com/chef/chef-dk/issues/50)


## [v0.15.15](https://github.com/chef/chef-dk/tree/v0.15.15) (2016-06-17)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.14.25...v0.15.15)

**Implemented enhancements:**

- Update test-kitchen to 1.10.0 [\#905](https://github.com/chef/chef-dk/pull/905) ([mwrock](https://github.com/mwrock))
- Add `build-cookbook` subcommand to `chef generate` and `--delivery` option to `chef generate cookbook` [\#891](https://github.com/chef/chef-dk/pull/891) ([danielsdeleo](https://github.com/danielsdeleo))
- Generators support ubuntu 16.04 and centos 7.2 by default [\#869](https://github.com/chef/chef-dk/pull/869) ([lamont-granquist](https://github.com/lamont-granquist))
- `chef --version` should print the Delivery CLI version [\#853](https://github.com/chef/chef-dk/pull/853) ([schisamo](https://github.com/schisamo))
- Adding the Git for Windows tools to the path if they are present [\#841](https://github.com/chef/chef-dk/pull/841) ([tyler-ball](https://github.com/tyler-ball))
- Generated .kitchen.yml defaults Inspec to doc format output [\#846](https://github.com/chef/chef-dk/pull/846) ([charlesjohnson](https://github.com/charlesjohnson))

**Fixed bugs:**

- Chef install does not use the embedded git [\#864](https://github.com/chef/chef-dk/issues/864)
- Unable to activate knife-solo-0.5.1 [\#811](https://github.com/chef/chef-dk/issues/811)
- Rubocop should install to chefdk/bin [\#865](https://github.com/chef/chef-dk/pull/865) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- Correct chef export usage message [\#859](https://github.com/chef/chef-dk/pull/859) ([philoserf](https://github.com/philoserf))


## [v0.14](https://github.com/chef/chef-dk/tree/v0.14.25) (2016-05-17)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.14.24...v0.14.25)

**Fixed bugs:**

- Test Kitchen does not apply my Policyfile-style cookbook on Windows Server [\#632](https://github.com/chef/chef-dk/issues/632)
- Attributes ignored in kitchen.yml with policyfile\_zero provisioner [\#460](https://github.com/chef/chef-dk/issues/460)
- Chef\_generator renames apache2 to apachev2 [\#822](https://github.com/chef/chef-dk/pull/822) ([charlesjohnson](https://github.com/charlesjohnson))
- Rubocop not present at /opt/chefdk/bin/rubocop in 0.13.5 [\#789](https://github.com/chef/chef-dk/issues/789)

**Implemented enhancements:**

- bumping test-kitchen and adding winrm-elevated [\#827](https://github.com/chef/chef-dk/pull/827) ([mwrock](https://github.com/mwrock))
- Include git on windows.  [\#814](https://github.com/chef/chef-dk/pull/814) ([tylercloke](https://github.com/tylercloke))
- Add cookstyle to ChefDK's omnibus package [\#808](https://github.com/chef/chef-dk/pull/808) ([danielsdeleo](https://github.com/danielsdeleo))
- Adding Delivery build node tools into the ChefDK [\#800](https://github.com/chef/chef-dk/pull/800) ([tyler-ball](https://github.com/tyler-ball))
- add delivery-cli to chefdk [\#798](https://github.com/chef/chef-dk/pull/798) ([marcparadise](https://github.com/marcparadise))


## [v0.13](https://github.com/chef/chef-dk/tree/v0.13.21) (2016-04-15)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.12.0...v0.13.21)

**Implemented enhancements:**

- Adds a bin stub for running rake dependencies on windows [\#795](https://github.com/chef/chef-dk/pull/795) ([mwrock](https://github.com/mwrock))
- Updating test-kitchen pin to 1.7.3 [\#794](https://github.com/chef/chef-dk/pull/794) ([mwrock](https://github.com/mwrock))
- Dependency bump to get the latest Chef release, 12.9.38 [\#791](https://github.com/chef/chef-dk/pull/791) ([tyler-ball](https://github.com/tyler-ball))
- Update everything to latest, start updating rubygems [\#786](https://github.com/chef/chef-dk/pull/786) ([jkeiser](https://github.com/jkeiser))
- Removing json from the Omnibus Gemfile because we worked around the bug [\#785](https://github.com/chef/chef-dk/pull/785) ([tyler-ball](https://github.com/tyler-ball))
- Update copyright date [\#787](https://github.com/chef/chef-dk/pull/787) ([adamedx](https://github.com/adamedx))
- Check in .bundle/config --without omnibus\_package --frozen [\#784](https://github.com/chef/chef-dk/pull/784) ([jkeiser](https://github.com/jkeiser))
- Install chef-dk from one gemfile [\#765](https://github.com/chef/chef-dk/pull/765) ([jkeiser](https://github.com/jkeiser))
- Add omnibus licensing metadata [\#777](https://github.com/chef/chef-dk/pull/777) ([patrick-wright](https://github.com/patrick-wright))
- Add descriptions to rake tasks to see them in `rake -T` [\#776](https://github.com/chef/chef-dk/pull/776) ([danielsdeleo](https://github.com/danielsdeleo))
- Set correct product and windows architecture for acceptance tests [\#752](https://github.com/chef/chef-dk/pull/752) ([mwrock](https://github.com/mwrock))
- Add version:bump and version:show to chef-dk [\#756](https://github.com/chef/chef-dk/pull/756) ([jkeiser](https://github.com/jkeiser))
- Use compiled ruby on windows [\#726](https://github.com/chef/chef-dk/pull/726) ([jkeiser](https://github.com/jkeiser))

**Fixed bugs:**
- Point to the right license file for chefdk. [\#781](https://github.com/chef/chef-dk/pull/781) ([sersut](https://github.com/sersut))
- Fixes the winrm-fs for win2k8r2 [\#778](https://github.com/chef/chef-dk/pull/778) ([mwrock](https://github.com/mwrock))
- Fix windows powershell command by prefixing run\_command with call operator [\#751](https://github.com/chef/chef-dk/pull/751) ([mwrock](https://github.com/mwrock))


## [0.12.0](https://github.com/chef/chef-dk/tree/0.12.0) (2016-03-14)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.11.2...0.12.0)

**Implemented enhancements:**

- Pin all omnibus software to latest release versions [\#739](https://github.com/chef/chef-dk/pull/739) ([danielsdeleo](https://github.com/danielsdeleo))
- Improve Chef-DK shortcut startup time by skipping powershell profile [\#734](https://github.com/chef/chef-dk/pull/734) ([adamedx](https://github.com/adamedx))
- Pin berkshelf to 4.3.0 [\#732](https://github.com/chef/chef-dk/pull/732) ([mwrock](https://github.com/mwrock))
- Clean up static libs at build time [\#724](https://github.com/chef/chef-dk/pull/724) ([chefsalim](https://github.com/chefsalim))
- Replace winrm-transport with winrm-fs and bump test-kitchen in omnibus gemfile [\#722](https://github.com/chef/chef-dk/pull/722) ([mwrock](https://github.com/mwrock))
- Update foodcritic to v6.0.1 [\#702](https://github.com/chef/chef-dk/pull/702) ([jaym](https://github.com/jaym))
- Bumping berkshelf version to 4.2.1 [\#697](https://github.com/chef/chef-dk/pull/697) ([someara](https://github.com/someara))

**Fixed bugs:**

- Chef Export no longer includes files outside of CookbookVersionLoader segments such as test/ or spec/ [\#709](https://github.com/chef/chef-dk/issues/709)

## [v0.11.2](https://github.com/chef/chef-dk/tree/v0.11.2) (2016-02-22)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.11.0...v0.11.2)

**Implemented enhancements:**

- Update Inspec and kitchen-inspec [\#700](https://github.com/chef/chef-dk/pull/700) ([chris-rock](https://github.com/chris-rock))
- Update to latest inspec and kitchen-inspec versions [\#698](https://github.com/chef/chef-dk/pull/698) ([chris-rock](https://github.com/chris-rock))
- Update berkshelf pin and chefdk version [\#690](https://github.com/chef/chef-dk/pull/690) ([chefsalim](https://github.com/chefsalim))
- elevate windows shortcuts [\#678](https://github.com/chef/chef-dk/pull/678) ([mwrock](https://github.com/mwrock))

**Fixed bugs:**

- Fix typo in builtin\_commands.rb [\#688](https://github.com/chef/chef-dk/pull/688) ([chefsalim](https://github.com/chefsalim))

## [0.11.0](https://github.com/chef/chef-dk/tree/0.11.0) (2016-02-12)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.10.0...0.11.0)

**Implemented enhancements:**

- chef-dk 0.7.0 chef Binary Should Support Alternate Config Files [\#518](https://github.com/chef/chef-dk/issues/518)
- Local Configuration? [\#473](https://github.com/chef/chef-dk/issues/473)
- Update rubocop and chef-provisioning drivers to latest version [\#670](https://github.com/chef/chef-dk/pull/670) ([tas50](https://github.com/tas50))
- add pry, pry-byebug, pry-remote to chef-dk [\#662](https://github.com/chef/chef-dk/pull/662) ([lamont-granquist](https://github.com/lamont-granquist))
- Native policy export [\#659](https://github.com/chef/chef-dk/pull/659) ([danielsdeleo](https://github.com/danielsdeleo))
- float vault on master [\#654](https://github.com/chef/chef-dk/pull/654) ([thommay](https://github.com/thommay))
- Sanity check run list item format in policy commands [\#635](https://github.com/chef/chef-dk/pull/635) ([danielsdeleo](https://github.com/danielsdeleo))
- Show policy revision id when running `chef install` [\#630](https://github.com/chef/chef-dk/pull/630) ([danielsdeleo](https://github.com/danielsdeleo))
- Add named\_run\_list support to provisioner [\#607](https://github.com/chef/chef-dk/pull/607) ([danielsdeleo](https://github.com/danielsdeleo))
- Load configuration when running `chef update` [\#605](https://github.com/chef/chef-dk/pull/605) ([danielsdeleo](https://github.com/danielsdeleo))

**Fixed bugs:**

- berks not working on OS X after upgrading to 0.10.0-1  [\#657](https://github.com/chef/chef-dk/issues/657)
- Policyfile should validate the recipes in the run list [\#629](https://github.com/chef/chef-dk/issues/629)
- Policyfile can normalize run list to an invalid value [\#625](https://github.com/chef/chef-dk/issues/625)
- after 'knife rehash' no 'knife download' subcommands available [\#624](https://github.com/chef/chef-dk/issues/624)
- Kitchen::Provisioner::PolicyfileZero does not respect chefignore [\#612](https://github.com/chef/chef-dk/issues/612)
- knife validatorless bootstrap + chef-vault Options Bootstrap and Rebootstrap  [\#610](https://github.com/chef/chef-dk/issues/610)
- NameError: uninitialized constant Chef::Provisioning::FogDriver::Driver::Cheff [\#592](https://github.com/chef/chef-dk/issues/592)
- Update ChefDK Rubocop to 0.34.2 or higher [\#588](https://github.com/chef/chef-dk/issues/588)
- \[Specinfra\] Windows convert\_regexp Consumes Forward Slashes [\#526](https://github.com/chef/chef-dk/issues/526)
- ChefDK Uninstallation on Windows [\#292](https://github.com/chef/chef-dk/issues/292)
- Artificially high time estimate for uninstalling [\#250](https://github.com/chef/chef-dk/issues/250)
- High CPU issue after installing ChefDK \(windows 8.1\) [\#144](https://github.com/chef/chef-dk/issues/144)
- Update ManufacturerName to be a cleaner string [\#675](https://github.com/chef/chef-dk/pull/675) ([chefsalim](https://github.com/chefsalim))
- Bring in bundler 1.11.2 and rubygems 2.5.2 [\#666](https://github.com/chef/chef-dk/pull/666) ([lamont-granquist](https://github.com/lamont-granquist))
- Better chef export error messages [\#665](https://github.com/chef/chef-dk/pull/665) ([danielsdeleo](https://github.com/danielsdeleo))
- Bump omnibus and update solaris mapfile [\#653](https://github.com/chef/chef-dk/pull/653) ([ksubrama](https://github.com/ksubrama))
- Better error message for invalid run lists in chef policy commands [\#647](https://github.com/chef/chef-dk/pull/647) ([danielsdeleo](https://github.com/danielsdeleo))
- Point knife-spork to master until knife-spork\#198 is fixed [\#645](https://github.com/chef/chef-dk/pull/645) ([ksubrama](https://github.com/ksubrama))
- Consume master of fauxhai [\#643](https://github.com/chef/chef-dk/pull/643) ([curiositycasualty](https://github.com/curiositycasualty))
- Bringing in open PRs with +1s from omnibus-chef [\#639](https://github.com/chef/chef-dk/pull/639) ([ksubrama](https://github.com/ksubrama))
- Update chef dependency to ~\> 12.5 [\#609](https://github.com/chef/chef-dk/pull/609) ([danielsdeleo](https://github.com/danielsdeleo))
- 'chef export' respects chefignore [\#606](https://github.com/chef/chef-dk/pull/606) ([danielsdeleo](https://github.com/danielsdeleo))
- Forcibly unset policyfile config in embedded chef runs [\#596](https://github.com/chef/chef-dk/pull/596) ([danielsdeleo](https://github.com/danielsdeleo))

## [v0.10.0](https://github.com/chef/chef-dk/tree/v0.10.0) (2015-11-05)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.9.0...v0.10.0)

**Fixed bugs:**

- `kitchen create` fails to pull down default centos-6.5 box [\#399](https://github.com/chef/chef-dk/issues/399)
- Test Kitchen: `join': No live threads left. Deadlock? \(fatal\) [\#309](https://github.com/chef/chef-dk/issues/309)
- Test Kitchen: `join': No live threads left. Deadlock? \\(fatal\\) [\#309](https://github.com/chef/chef-dk/issues/309)

**Closed issues:**

- chef generate overwrites the readme.md if present. [\#577](https://github.com/chef/chef-dk/issues/577)
- Cookbook path error message [\#564](https://github.com/chef/chef-dk/issues/564)
- ChefDK 0.8.0 install on Windows breaks existing $env:PSModulePath until environment is restarted [\#534](https://github.com/chef/chef-dk/issues/534)
- "chef shell-init powershell" fails on Windows 8.1 in OOB configuration [\#448](https://github.com/chef/chef-dk/issues/448)
- chef vault refresh and chef-client 12.4.0 [\#447](https://github.com/chef/chef-dk/issues/447)
- Ohai locks up computer if on Active Directory [\#439](https://github.com/chef/chef-dk/issues/439)
- missing knife plugins after chef-dk upgrade [\#427](https://github.com/chef/chef-dk/issues/427)
- chefdk\[:generator\_cookbook\] setting in knife.rb or config.rb causes knife commands to fail [\#375](https://github.com/chef/chef-dk/issues/375)

**Merged pull requests:**

- Fix incorrect suggested code in errors [\#591](https://github.com/chef/chef-dk/pull/591) ([danielsdeleo](https://github.com/danielsdeleo))
- Return correct type when filtering out cookbooks from graph [\#590](https://github.com/chef/chef-dk/pull/590) ([danielsdeleo](https://github.com/danielsdeleo))
- Adding `chef verify inspec` and Test Kitchen verifier to generators \(commented out\) [\#589](https://github.com/chef/chef-dk/pull/589) ([tyler-ball](https://github.com/tyler-ball))
- Preferred supermarkets for cookbooks [\#587](https://github.com/chef/chef-dk/pull/587) ([danielsdeleo](https://github.com/danielsdeleo))
- Remove unused test scripts directory [\#586](https://github.com/chef/chef-dk/pull/586) ([danielsdeleo](https://github.com/danielsdeleo))
- Configurable depsolver [\#584](https://github.com/chef/chef-dk/pull/584) ([danielsdeleo](https://github.com/danielsdeleo))
- Only report cookbook source conflicts that could affect solution [\#581](https://github.com/chef/chef-dk/pull/581) ([danielsdeleo](https://github.com/danielsdeleo))
- Update new tests to run out of chef-dk gem dir. [\#580](https://github.com/chef/chef-dk/pull/580) ([ksubrama](https://github.com/ksubrama))
- Add :delivery\_supermarket default source type [\#574](https://github.com/chef/chef-dk/pull/574) ([danielsdeleo](https://github.com/danielsdeleo))
- Verify that generated cookbooks pass chefspec [\#572](https://github.com/chef/chef-dk/pull/572) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix typo in warning.txt. Obvious fix. [\#567](https://github.com/chef/chef-dk/pull/567) ([tonyflint](https://github.com/tonyflint))
- Better "not a cookbook" errors [\#566](https://github.com/chef/chef-dk/pull/566) ([danielsdeleo](https://github.com/danielsdeleo))
- Make chef repo prefer policyfiles [\#563](https://github.com/chef/chef-dk/pull/563) ([danielsdeleo](https://github.com/danielsdeleo))
- Update chef verify to pull component tests from gems [\#562](https://github.com/chef/chef-dk/pull/562) ([ksubrama](https://github.com/ksubrama))
- Update POLICYFILE\_README for the current state of the world [\#560](https://github.com/chef/chef-dk/pull/560) ([danielsdeleo](https://github.com/danielsdeleo))
- Add gemspec files to allow bundler to run from the gem [\#559](https://github.com/chef/chef-dk/pull/559) ([ksubrama](https://github.com/ksubrama))
- Make Generated Cookbook Use ChefSpec Policyfile Mode [\#557](https://github.com/chef/chef-dk/pull/557) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.9.0](https://github.com/chef/chef-dk/tree/0.9.0) (2015-10-07)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.8.1...0.9.0)

**Fixed bugs:**

- chefdk 0.9.0-pre on Windows 10 and 2012r2 generates cookbooks that don't pass chefspec [\#546](https://github.com/chef/chef-dk/issues/546)
- chefdk 0.9.0-pre on Windows 10 and 2012r2 generates cookbooks that don't pass chefspec [\#546](https://github.com/chef/chef-dk/issues/546)
- chef verify doesn't work after installing chefdk 0.7.0 on Windows7 [\#482](https://github.com/chef/chef-dk/issues/482)

**Closed issues:**

- generate repo doesn't git init [\#551](https://github.com/chef/chef-dk/issues/551)

**Merged pull requests:**

- Generate Policyfiles instead of Berksfiles in new cookbooks [\#555](https://github.com/chef/chef-dk/pull/555) ([danielsdeleo](https://github.com/danielsdeleo))
- add git init condition to prevent init inside an existing git repository [\#554](https://github.com/chef/chef-dk/pull/554) ([keen99](https://github.com/keen99))
- Fix typographical error\(s\) [\#550](https://github.com/chef/chef-dk/pull/550) ([orthographic-pedant](https://github.com/orthographic-pedant))
- Further customize kitchen to avoid berksfile detection [\#545](https://github.com/chef/chef-dk/pull/545) ([danielsdeleo](https://github.com/danielsdeleo))
- Generate generator [\#544](https://github.com/chef/chef-dk/pull/544) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.8.1](https://github.com/chef/chef-dk/tree/0.8.1) (2015-09-30)
[Full Changelog](https://github.com/chef/chef-dk/compare/v0.8.0...0.8.1)

**Closed issues:**

- shell-init broken for both bash and zsh in 0.8.0 [\#537](https://github.com/chef/chef-dk/issues/537)
- Conflict using `bundler` inside `chefdk` [\#536](https://github.com/chef/chef-dk/issues/536)
- Chefdk 0.8.0 not working on Debian 7 Wheezy because of libc version mismatch [\#533](https://github.com/chef/chef-dk/issues/533)
- cookbook\_file is not working with Test-kitchen with windows server through vagrant [\#512](https://github.com/chef/chef-dk/issues/512)
- WIN 8 no knife configuration found [\#484](https://github.com/chef/chef-dk/issues/484)
- chefdk preventing vagrant from working [\#466](https://github.com/chef/chef-dk/issues/466)

**Merged pull requests:**

- Verify that the policyfile\_zero provisioner can load [\#539](https://github.com/chef/chef-dk/pull/539) ([danielsdeleo](https://github.com/danielsdeleo))
- Enable strict config, catch config errors in command base [\#535](https://github.com/chef/chef-dk/pull/535) ([danielsdeleo](https://github.com/danielsdeleo))
- Include a valid config in exported policies [\#532](https://github.com/chef/chef-dk/pull/532) ([danielsdeleo](https://github.com/danielsdeleo))

## [v0.8.0](https://github.com/chef/chef-dk/tree/v0.8.0) (2015-09-22)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.7.0...v0.8.0)

**Implemented enhancements:**

- remove beta warnings from policyfile commands [\#513](https://github.com/chef/chef-dk/pull/513) ([danielsdeleo](https://github.com/danielsdeleo))
- Support OS/X 10.11 package installation [\#509](https://github.com/chef/chef-dk/pull/509) ([sersut](https://github.com/sersut))
- Add `chef delete-policy` subcommand [\#501](https://github.com/chef/chef-dk/pull/501) ([danielsdeleo](https://github.com/danielsdeleo))
- Add command line completion for fish shell [\#498](https://github.com/chef/chef-dk/pull/498) ([smith](https://github.com/smith))
- Add `chef clean-policy-cookbooks` subcommand [\#496](https://github.com/chef/chef-dk/pull/496) ([danielsdeleo](https://github.com/danielsdeleo))
- `chef clean-policy-revisions` command [\#491](https://github.com/chef/chef-dk/pull/491) ([danielsdeleo](https://github.com/danielsdeleo))
- `chef undelete` command [\#490](https://github.com/chef/chef-dk/pull/490) ([danielsdeleo](https://github.com/danielsdeleo))
- Add shell completion for bash [\#487](https://github.com/chef/chef-dk/pull/487) ([danielsdeleo](https://github.com/danielsdeleo))
- Add basic zsh completion for chef command [\#485](https://github.com/chef/chef-dk/pull/485) ([danielsdeleo](https://github.com/danielsdeleo))
- `chef rm-policy-group` CLI [\#483](https://github.com/chef/chef-dk/pull/483) ([danielsdeleo](https://github.com/danielsdeleo))
- Update URLs to https where available [\#479](https://github.com/chef/chef-dk/pull/479) ([tas50](https://github.com/tas50))

**Fixed bugs:**

- chef install doesn't seem to use the Default SSL Policy [\#488](https://github.com/chef/chef-dk/issues/488)
- berks: Add support for no\_proxy environment variable when using http\_proxy [\#486](https://github.com/chef/chef-dk/issues/486)
- chef-dk gem out of date [\#475](https://github.com/chef/chef-dk/issues/475)
- Ubuntu 15.04 error message: The package is of bad quality [\#457](https://github.com/chef/chef-dk/issues/457)
- knife segmentation fault on YN prompt in ConEmu [\#434](https://github.com/chef/chef-dk/issues/434)
- chefdk msi is not signed; publisher couldn't be verified [\#154](https://github.com/chef/chef-dk/issues/154)
- Make `chef verify` test for multiple versions of provisioning gems [\#521](https://github.com/chef/chef-dk/pull/521) ([randomcamel](https://github.com/randomcamel))
- Include named\_run\_lists when deserializing a lockfile [\#520](https://github.com/chef/chef-dk/pull/520) ([danielsdeleo](https://github.com/danielsdeleo))
- Remove mixlib-shellout RC from gemspec [\#499](https://github.com/chef/chef-dk/pull/499) ([danielsdeleo](https://github.com/danielsdeleo))
- Always show 'no policy' message when policy doesn't exist [\#495](https://github.com/chef/chef-dk/pull/495) ([danielsdeleo](https://github.com/danielsdeleo))
- Chef install configuration [\#489](https://github.com/chef/chef-dk/pull/489) ([danielsdeleo](https://github.com/danielsdeleo))
- Show full usage when given invalid args [\#477](https://github.com/chef/chef-dk/pull/477) ([danielsdeleo](https://github.com/danielsdeleo))
- Catch bad params [\#468](https://github.com/chef/chef-dk/pull/468) ([danielsdeleo](https://github.com/danielsdeleo))

**Merged pull requests:**

- Use github\_changelog\_generator for changelog [\#527](https://github.com/chef/chef-dk/pull/527) ([jkeiser](https://github.com/jkeiser))
- Add service class to GC cookbook\_artifacts [\#463](https://github.com/chef/chef-dk/pull/463) ([danielsdeleo](https://github.com/danielsdeleo))
- Backend for policy group removal [\#461](https://github.com/chef/chef-dk/pull/461) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.7.0](https://github.com/chef/chef-dk/tree/0.7.0) (2015-08-05)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.7.0.rc.4...0.7.0)

**Merged pull requests:**

- Mockup policyfile revision cleanup [\#456](https://github.com/chef/chef-dk/pull/456) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.7.0.rc.4](https://github.com/chef/chef-dk/tree/0.7.0.rc.4) (2015-07-27)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.7.0.rc.3...0.7.0.rc.4)

## [0.7.0.rc.3](https://github.com/chef/chef-dk/tree/0.7.0.rc.3) (2015-07-20)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.7.0.rc.2...0.7.0.rc.3)

**Implemented enhancements:**

- support chef\_repo & supermarket sources together [\#430](https://github.com/chef/chef-dk/issues/430)

**Merged pull requests:**

- Policyfile doc updates [\#451](https://github.com/chef/chef-dk/pull/451) ([danielsdeleo](https://github.com/danielsdeleo))
- Add `chef verify chef-provisioning` [\#433](https://github.com/chef/chef-dk/pull/433) ([randomcamel](https://github.com/randomcamel))

## [0.7.0.rc.2](https://github.com/chef/chef-dk/tree/0.7.0.rc.2) (2015-07-08)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.7.0.rc.1...0.7.0.rc.2)

**Closed issues:**

- 0.7.0, gems in user install not showing up: [\#443](https://github.com/chef/chef-dk/issues/443)
- rubygems undefined method `activate' for nil:NilClass [\#411](https://github.com/chef/chef-dk/issues/411)

**Merged pull requests:**

- Multiple policyfile sources [\#450](https://github.com/chef/chef-dk/pull/450) ([danielsdeleo](https://github.com/danielsdeleo))
- Prevent kitchen from installing gems in smoke tests [\#449](https://github.com/chef/chef-dk/pull/449) ([danielsdeleo](https://github.com/danielsdeleo))
- Revert "Pin FFI to 1.9.8 because 1.9.9 breaks on windows" [\#446](https://github.com/chef/chef-dk/pull/446) ([jaym](https://github.com/jaym))
- Pin FFI to 1.9.8 because 1.9.9 breaks on windows [\#442](https://github.com/chef/chef-dk/pull/442) ([danielsdeleo](https://github.com/danielsdeleo))
- Push Archive Command [\#438](https://github.com/chef/chef-dk/pull/438) ([danielsdeleo](https://github.com/danielsdeleo))
- Adding pre-release install instructions [\#437](https://github.com/chef/chef-dk/pull/437) ([tyler-ball](https://github.com/tyler-ball))

## [0.7.0.rc.1](https://github.com/chef/chef-dk/tree/0.7.0.rc.1) (2015-06-24)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.7.0.rc.0...0.7.0.rc.1)

**Implemented enhancements:**

- Roles and Environments should have identical implementations [\#182](https://github.com/chef/chef-dk/issues/182)

**Fixed bugs:**

- ChefDK's chef generate command fails with Insufficient permissions after cd'ing to a different directory [\#340](https://github.com/chef/chef-dk/issues/340)

**Closed issues:**

- rbreadline crashes if HOMEDRIVE is unavailable [\#415](https://github.com/chef/chef-dk/issues/415)
- Running talilor gem causes ruby to crash [\#349](https://github.com/chef/chef-dk/issues/349)

**Merged pull requests:**

- Add stuff I missed to changelog for 0.7 [\#436](https://github.com/chef/chef-dk/pull/436) ([danielsdeleo](https://github.com/danielsdeleo))
- Export archive [\#432](https://github.com/chef/chef-dk/pull/432) ([danielsdeleo](https://github.com/danielsdeleo))
- Adding policyfile usage instructions to POLICYFILE\_README.md [\#431](https://github.com/chef/chef-dk/pull/431) ([tyler-ball](https://github.com/tyler-ball))
- Fix RSpec warnings for "potential false positives" [\#428](https://github.com/chef/chef-dk/pull/428) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.7.0.rc.0](https://github.com/chef/chef-dk/tree/0.7.0.rc.0) (2015-06-17)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.6.2...0.7.0.rc.0)

**Implemented enhancements:**

- Installing gems to network drives in Windows domain environments is slow and painful [\#374](https://github.com/chef/chef-dk/issues/374)

**Closed issues:**

- chef-provisioning included with the Chef DK is current at v 1.1.1, however the latest is 1.2.0.  [\#409](https://github.com/chef/chef-dk/issues/409)
- Chefspec tests trigger segfault on chef dk 0.4.0 on Windows [\#332](https://github.com/chef/chef-dk/issues/332)

**Merged pull requests:**

- Missing changelog entries [\#426](https://github.com/chef/chef-dk/pull/426) ([jaym](https://github.com/jaym))
- Show specific policy [\#424](https://github.com/chef/chef-dk/pull/424) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.6.2](https://github.com/chef/chef-dk/tree/0.6.2) (2015-06-12)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.6.1...0.6.2)

**Fixed bugs:**

- SSL requests broken in ChefDK [\#420](https://github.com/chef/chef-dk/issues/420)

**Closed issues:**

- ChefDK does not install successfully on Mac OS X El Capitan developer seed [\#419](https://github.com/chef/chef-dk/issues/419)

**Merged pull requests:**

- Added chef env command [\#423](https://github.com/chef/chef-dk/pull/423) ([jaym](https://github.com/jaym))
- Adding verification for openssl Windows issue to prevent regression, fixes \#420 [\#422](https://github.com/chef/chef-dk/pull/422) ([tyler-ball](https://github.com/tyler-ball))
- Testing out chef-provisioning 1.2 and knife-windows 1.0 RC [\#414](https://github.com/chef/chef-dk/pull/414) ([tyler-ball](https://github.com/tyler-ball))
- Allow setting CHEFDK\_HOME [\#412](https://github.com/chef/chef-dk/pull/412) ([jaym](https://github.com/jaym))

## [0.6.1](https://github.com/chef/chef-dk/tree/0.6.1) (2015-06-12)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.6.0...0.6.1)

**Implemented enhancements:**

- Include knife-windows gem + deps in the ChefDK gemset [\#107](https://github.com/chef/chef-dk/issues/107)

**Fixed bugs:**

- ChefDK 0.5.1 knife Needs STDERR Redirection for Cookbook Version Selection Deletion [\#393](https://github.com/chef/chef-dk/issues/393)

**Closed issues:**

- read server certificate B: certificate verify failed [\#410](https://github.com/chef/chef-dk/issues/410)
- FATAL: ArgumentError: invalid Unicode escape on Windows because of recipe name [\#389](https://github.com/chef/chef-dk/issues/389)
- kitchen-vagrant errors [\#378](https://github.com/chef/chef-dk/issues/378)

**Merged pull requests:**

- Adding verification for openssl issue, fixes https://github.com/chef/chef-dk/issues/420 [\#421](https://github.com/chef/chef-dk/pull/421) ([tyler-ball](https://github.com/tyler-ball))
- Integrate show policy command [\#417](https://github.com/chef/chef-dk/pull/417) ([danielsdeleo](https://github.com/danielsdeleo))
- Revert "Merge pull request \#398 from chef/schisamo/delivery-cli" [\#408](https://github.com/chef/chef-dk/pull/408) ([christophermaier](https://github.com/christophermaier))
- Provision target host option and arbitrary options [\#406](https://github.com/chef/chef-dk/pull/406) ([danielsdeleo](https://github.com/danielsdeleo))
- Add `chef show-policy` command [\#405](https://github.com/chef/chef-dk/pull/405) ([danielsdeleo](https://github.com/danielsdeleo))
- Update to Solve 2 with Molinillo solver [\#400](https://github.com/chef/chef-dk/pull/400) ([danielsdeleo](https://github.com/danielsdeleo))
- Add basic smoke tests for the Delivery CLI [\#398](https://github.com/chef/chef-dk/pull/398) ([schisamo](https://github.com/schisamo))

## [0.6.0](https://github.com/chef/chef-dk/tree/0.6.0) (2015-05-14)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.5.1...0.6.0)

**Fixed bugs:**

- Policyfile git detection blows up in a brand new repo [\#364](https://github.com/chef/chef-dk/issues/364)

**Closed issues:**

- Chef 0.5.1 does not show berks version [\#387](https://github.com/chef/chef-dk/issues/387)
- chef generate cookbook makes cookbooks that don't pass rubocop [\#380](https://github.com/chef/chef-dk/issues/380)
- knife encountered an unexpected error [\#379](https://github.com/chef/chef-dk/issues/379)
- ERROR -- : Actor crashed! Solution - Upgrade Berkshelf to 3.2.4 [\#376](https://github.com/chef/chef-dk/issues/376)

**Merged pull requests:**

- Pinning chef-provisioning to 1.1.1 [\#394](https://github.com/chef/chef-dk/pull/394) ([tyler-ball](https://github.com/tyler-ball))
- Don't error when profiling an unborn branch [\#392](https://github.com/chef/chef-dk/pull/392) ([danielsdeleo](https://github.com/danielsdeleo))
- bump chef-dk ffi-yajl dep [\#391](https://github.com/chef/chef-dk/pull/391) ([lamont-granquist](https://github.com/lamont-granquist))
- Provision command [\#383](https://github.com/chef/chef-dk/pull/383) ([danielsdeleo](https://github.com/danielsdeleo))
- Fixes \#380, resolve generated cookbook rubocops [\#381](https://github.com/chef/chef-dk/pull/381) ([jtimberman](https://github.com/jtimberman))

## [0.5.1](https://github.com/chef/chef-dk/tree/0.5.1) (2015-04-30)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.5.0...0.5.1)

**Fixed bugs:**

- Chef diff throws undefined\_method error [\#366](https://github.com/chef/chef-dk/issues/366)

**Closed issues:**

- en list [\#371](https://github.com/chef/chef-dk/issues/371)
- default-centos-64 is not available [\#369](https://github.com/chef/chef-dk/issues/369)
- Chef diff trying to use native endpoints in compatability mode [\#367](https://github.com/chef/chef-dk/issues/367)
- gem excon 0.44.2 fixes nasty bug, please include in next release [\#344](https://github.com/chef/chef-dk/issues/344)
- Please add documentation for Chef shell-init [\#338](https://github.com/chef/chef-dk/issues/338)

**Merged pull requests:**

- Preparing the ChefDK 0.5.1 release [\#373](https://github.com/chef/chef-dk/pull/373) ([tyler-ball](https://github.com/tyler-ball))
- Fixing undefined\_method error [\#368](https://github.com/chef/chef-dk/pull/368) ([tyler-ball](https://github.com/tyler-ball))

## [0.5.0](https://github.com/chef/chef-dk/tree/0.5.0) (2015-04-29)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.5.0.rc.5...0.5.0)

**Closed issues:**

- Arch Linux support [\#355](https://github.com/chef/chef-dk/issues/355)
- ChefDK 0.4.0 cheffish chef-zero dependency conflict [\#347](https://github.com/chef/chef-dk/issues/347)
- ChefDK 0.5.0 rc3 shipped with bad versions of chef-provisioning and friends [\#346](https://github.com/chef/chef-dk/issues/346)

**Merged pull requests:**

- Update shell-init docs for posh and fish [\#365](https://github.com/chef/chef-dk/pull/365) ([danielsdeleo](https://github.com/danielsdeleo))
- Preping for 0.5.0 release with CHANGELOG updates and version file update [\#363](https://github.com/chef/chef-dk/pull/363) ([tyler-ball](https://github.com/tyler-ball))
- Enable policyfile native mode by default, remove warning [\#362](https://github.com/chef/chef-dk/pull/362) ([danielsdeleo](https://github.com/danielsdeleo))
- Use a stub to ensure we always test file-not-readable behavior [\#361](https://github.com/chef/chef-dk/pull/361) ([danielsdeleo](https://github.com/danielsdeleo))
- CLI front-end for diff [\#359](https://github.com/chef/chef-dk/pull/359) ([danielsdeleo](https://github.com/danielsdeleo))
- Add Policy Differ Class [\#356](https://github.com/chef/chef-dk/pull/356) ([danielsdeleo](https://github.com/danielsdeleo))
- Attribute only update [\#354](https://github.com/chef/chef-dk/pull/354) ([danielsdeleo](https://github.com/danielsdeleo))
- Ensure attributes are maintained in deserialization [\#352](https://github.com/chef/chef-dk/pull/352) ([danielsdeleo](https://github.com/danielsdeleo))
- Policyfile attributes [\#351](https://github.com/chef/chef-dk/pull/351) ([danielsdeleo](https://github.com/danielsdeleo))
- Disabling test that fails intermitently on debian [\#350](https://github.com/chef/chef-dk/pull/350) ([tyler-ball](https://github.com/tyler-ball))
- add chef\_repo cookbook source [\#263](https://github.com/chef/chef-dk/pull/263) ([lamont-granquist](https://github.com/lamont-granquist))

## [0.5.0.rc.5](https://github.com/chef/chef-dk/tree/0.5.0.rc.5) (2015-04-06)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.5.0.rc.4...0.5.0.rc.5)

**Merged pull requests:**

- Changes link to point to downloads.chef.io [\#348](https://github.com/chef/chef-dk/pull/348) ([cwebberOps](https://github.com/cwebberOps))
- Add Fish shell support to `chef shell-init` [\#345](https://github.com/chef/chef-dk/pull/345) ([schisamo](https://github.com/schisamo))

## [0.5.0.rc.4](https://github.com/chef/chef-dk/tree/0.5.0.rc.4) (2015-04-03)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.5.0.rc.3...0.5.0.rc.4)

## [0.5.0.rc.3](https://github.com/chef/chef-dk/tree/0.5.0.rc.3) (2015-04-01)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.5.0.rc.2...0.5.0.rc.3)

**Closed issues:**

- chefdk installer crashes on windows unless previously uninstalled version is removed from disk [\#334](https://github.com/chef/chef-dk/issues/334)

## [0.5.0.rc.2](https://github.com/chef/chef-dk/tree/0.5.0.rc.2) (2015-03-27)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.5.0.rc.1...0.5.0.rc.2)

## [0.5.0.rc.1](https://github.com/chef/chef-dk/tree/0.5.0.rc.1) (2015-03-26)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.4.0...0.5.0.rc.1)

**Implemented enhancements:**

- Generators should read metadata values from chef/knife configuration [\#322](https://github.com/chef/chef-dk/issues/322)
- OSX: Pull certs from Keychain [\#140](https://github.com/chef/chef-dk/issues/140)

**Fixed bugs:**

- Chef Linux Group Provider is not indempotent [\#336](https://github.com/chef/chef-dk/issues/336)
- Ubuntu 14.04 bad quality package [\#316](https://github.com/chef/chef-dk/issues/316)
- Windows 8.1 \>\> berks install fails SSLv3 error [\#311](https://github.com/chef/chef-dk/issues/311)
- Downloads for ubuntu 14.04? [\#308](https://github.com/chef/chef-dk/issues/308)
- ruby -w shows warnings because user\_dir is overridden [\#302](https://github.com/chef/chef-dk/issues/302)
- ruby -w shows warnings because user\\_dir is overridden [\#302](https://github.com/chef/chef-dk/issues/302)
- chef-provisioning fails, bad chef\_server\_url, should be updated to latest 'master' branch [\#297](https://github.com/chef/chef-dk/issues/297)
- chef-provisioning fails, bad chef\\_server\\_url, should be updated to latest 'master' branch [\#297](https://github.com/chef/chef-dk/issues/297)
- "chef install" with policy file and a local chef zero fails to write to tmp dir [\#293](https://github.com/chef/chef-dk/issues/293)
- Celluloid Errors / Compatibility with ChefDK 0.3.5 [\#284](https://github.com/chef/chef-dk/issues/284)
- chefdk-0.3.2-1 - windows - rubocop.bat - bad path to ruby.exe [\#221](https://github.com/chef/chef-dk/issues/221)
- gitignore file not created when chef generate cookbook used in chef-site repo [\#145](https://github.com/chef/chef-dk/issues/145)
- chef --version should print the version of included tools in addition to chef-dk [\#48](https://github.com/chef/chef-dk/issues/48)
- Updating to use new shells available to windows-guest-branch of test-kitchen [\#305](https://github.com/chef/chef-dk/pull/305) ([tyler-ball](https://github.com/tyler-ball))

**Closed issues:**

- chef gem install guard-foodcritic not working [\#335](https://github.com/chef/chef-dk/issues/335)
- chefdk checking old location of 'client.rb' and client.rb seems to be corrupt [\#328](https://github.com/chef/chef-dk/issues/328)
- chefdk, vagrant, berkshelf mac osx [\#326](https://github.com/chef/chef-dk/issues/326)
- knife ssl check failure on Windows 7 [\#319](https://github.com/chef/chef-dk/issues/319)
- Wrong path for ruby.exe for ChefDK 0.3.5 on Windows for Several Commands [\#242](https://github.com/chef/chef-dk/issues/242)
- chef shell-init should support powershell and cmd [\#186](https://github.com/chef/chef-dk/issues/186)
- chef-zero not working with 0.2.2 [\#168](https://github.com/chef/chef-dk/issues/168)
- Request: Can we include unit testing skeletons with recipe generators? [\#152](https://github.com/chef/chef-dk/issues/152)
- chef generate cookbook: documentation on customizing output [\#62](https://github.com/chef/chef-dk/issues/62)

**Merged pull requests:**

- ChefDK 0.5.0.rc.1 Release [\#343](https://github.com/chef/chef-dk/pull/343) ([tyler-ball](https://github.com/tyler-ball))
- Empty Cookbook Options Fix [\#342](https://github.com/chef/chef-dk/pull/342) ([danielsdeleo](https://github.com/danielsdeleo))
- Erchef Policyfile integration [\#341](https://github.com/chef/chef-dk/pull/341) ([danielsdeleo](https://github.com/danielsdeleo))
- doc: explicit brew install. [\#337](https://github.com/chef/chef-dk/pull/337) ([lloydde](https://github.com/lloydde))
- Excluding failing tests from nightlies [\#333](https://github.com/chef/chef-dk/pull/333) ([tyler-ball](https://github.com/tyler-ball))
- Print versions of common tools when doing --version on chef-dk [\#327](https://github.com/chef/chef-dk/pull/327) ([kmacgugan](https://github.com/kmacgugan))
- Fix code formatting, add missing code formatting. [\#324](https://github.com/chef/chef-dk/pull/324) ([mbrukman](https://github.com/mbrukman))
- Policyfile Revision IDs [\#323](https://github.com/chef/chef-dk/pull/323) ([danielsdeleo](https://github.com/danielsdeleo))
- Point to supermarket for CLA links [\#321](https://github.com/chef/chef-dk/pull/321) ([danielsdeleo](https://github.com/danielsdeleo))
- Upload to Cookbook Artifacts API when Native Mode is Enabled [\#318](https://github.com/chef/chef-dk/pull/318) ([danielsdeleo](https://github.com/danielsdeleo))
- Use stronger language when warning about native API. [\#317](https://github.com/chef/chef-dk/pull/317) ([danielsdeleo](https://github.com/danielsdeleo))
- Add chefspec and serverspec to the CHANGELOG [\#314](https://github.com/chef/chef-dk/pull/314) ([nathenharvey](https://github.com/nathenharvey))
- Change location of serverspec spec\_helper.rb file [\#307](https://github.com/chef/chef-dk/pull/307) ([charlesjohnson](https://github.com/charlesjohnson))

## [0.4.0](https://github.com/chef/chef-dk/tree/0.4.0) (2015-01-29)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.3.6...0.4.0)

**Implemented enhancements:**

- chef gem install should avoid installing RI doc [\#264](https://github.com/chef/chef-dk/issues/264)

**Fixed bugs:**

- Unable to use ChefDK as Your Primary Development Environment [\#256](https://github.com/chef/chef-dk/issues/256)

**Closed issues:**

- `knife` doesn't work on fresh install [\#303](https://github.com/chef/chef-dk/issues/303)
- `chef verify` fails on windows \("Verification of component 'chefspec' failed."\) [\#298](https://github.com/chef/chef-dk/issues/298)
- Chef DK 0.3.6 windows download missing [\#296](https://github.com/chef/chef-dk/issues/296)
- How to get current components version? [\#295](https://github.com/chef/chef-dk/issues/295)
- Chef DK on MS WIndows instructions [\#288](https://github.com/chef/chef-dk/issues/288)
- Update to berkshelf 3.2.2 \(released Dec 18, 2014\) [\#286](https://github.com/chef/chef-dk/issues/286)

**Merged pull requests:**

- Bump version to 0.4.0 [\#304](https://github.com/chef/chef-dk/pull/304) ([jaym](https://github.com/jaym))
- Policyfile Native API support for `chef push` [\#299](https://github.com/chef/chef-dk/pull/299) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.3.6](https://github.com/chef/chef-dk/tree/0.3.6) (2015-01-14)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.3.5...0.3.6)

**Implemented enhancements:**

- Request: Allow generator cookbook path to be a git repo [\#190](https://github.com/chef/chef-dk/issues/190)

**Fixed bugs:**

- ChefDK for OS X \(.dmg file\) and Ubuntu \(.deb\) breaks ...site install because of no metadata.rb [\#285](https://github.com/chef/chef-dk/issues/285)
- ChefSpec unusably slow in ChefDK \> 0.3.2 [\#280](https://github.com/chef/chef-dk/issues/280)
- bundle install with Nokogiri gem fails [\#278](https://github.com/chef/chef-dk/issues/278)
- Installing Chef-DK on OSX to non-system drive results in broken scripts [\#247](https://github.com/chef/chef-dk/issues/247)
- Chef exec does not pass variables to specified executable correctly [\#244](https://github.com/chef/chef-dk/issues/244)
- Cannot load such file -- chef/encrypted\_data\_bag\_item/check\_encrypted [\#227](https://github.com/chef/chef-dk/issues/227)
- Windows PATH separator wrong in Chef exec command [\#180](https://github.com/chef/chef-dk/issues/180)
- chefspec and segmentation fault using chefdk 0.2.0 on windows 7 [\#171](https://github.com/chef/chef-dk/issues/171)
- chefspec and segmentation fault using chefdk 0.2.0 on windows 7 [\#171](https://github.com/chef/chef-dk/issues/171)

**Closed issues:**

- berks-api fails due to json gem version conflict [\#281](https://github.com/chef/chef-dk/issues/281)
- /opt/vagrant/embedded/lib/ruby/2.0.0/net/http.rb:918:in `connect': SSL\_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed \(OpenSSL::SSL::SSLError\) [\#279](https://github.com/chef/chef-dk/issues/279)
- kitchen verify is broken [\#276](https://github.com/chef/chef-dk/issues/276)
- Running any chef command returns ohai error [\#273](https://github.com/chef/chef-dk/issues/273)
- some cookbook dependencies are breaking chefspec [\#272](https://github.com/chef/chef-dk/issues/272)
- We ship old versions of Chef with ChefDK [\#267](https://github.com/chef/chef-dk/issues/267)
- Gem conflicts [\#252](https://github.com/chef/chef-dk/issues/252)
- Hardcoded "opscode" path [\#251](https://github.com/chef/chef-dk/issues/251)
- OSX Uninstallation instructions are wrong [\#248](https://github.com/chef/chef-dk/issues/248)
- Knife Bootstrap breaks when bootstrapping Ubuntu 14.04 node via chefdk 12.0.0.rc.0 [\#246](https://github.com/chef/chef-dk/issues/246)
- Can't execute bin after chef gem install [\#239](https://github.com/chef/chef-dk/issues/239)
- Certain knife operations result in exception on `chef/encrypted\_data\_bag\_item/check\_encrypted` [\#238](https://github.com/chef/chef-dk/issues/238)
- Print `chef shell-init` WARN to stderr [\#237](https://github.com/chef/chef-dk/issues/237)
- Broken Link in Chef Docs for 'docs.gethef.com' [\#236](https://github.com/chef/chef-dk/issues/236)

**Merged pull requests:**

- chefdk 0.3.6 [\#294](https://github.com/chef/chef-dk/pull/294) ([jaym](https://github.com/jaym))
- Add serverspec to cookbook & app generators [\#290](https://github.com/chef/chef-dk/pull/290) ([charlesjohnson](https://github.com/charlesjohnson))
- Adding omnibus-chef 318 to release notes [\#283](https://github.com/chef/chef-dk/pull/283) ([tyler-ball](https://github.com/tyler-ball))
- Multi Run List Support for Policyfiles \(ChefDK portion\) [\#277](https://github.com/chef/chef-dk/pull/277) ([danielsdeleo](https://github.com/danielsdeleo))
- Allow relative paths for generator cookbook config [\#274](https://github.com/chef/chef-dk/pull/274) ([danielsdeleo](https://github.com/danielsdeleo))
- Update CHANGELOG for recent generator and policyfile enhancements [\#271](https://github.com/chef/chef-dk/pull/271) ([danielsdeleo](https://github.com/danielsdeleo))
- Configure generator cookbook in ~/.chef/config.rb [\#270](https://github.com/chef/chef-dk/pull/270) ([danielsdeleo](https://github.com/danielsdeleo))
- Added appveyor yaml [\#269](https://github.com/chef/chef-dk/pull/269) ([jaym](https://github.com/jaym))
- Add chefspec to generators [\#266](https://github.com/chef/chef-dk/pull/266) ([charlesjohnson](https://github.com/charlesjohnson))
- Custom generator cookbook names [\#265](https://github.com/chef/chef-dk/pull/265) ([danielsdeleo](https://github.com/danielsdeleo))
- Simple `chef update` Command [\#262](https://github.com/chef/chef-dk/pull/262) ([danielsdeleo](https://github.com/danielsdeleo))
- Removing things from verify that don't work [\#261](https://github.com/chef/chef-dk/pull/261) ([jaym](https://github.com/jaym))
- Add kitchen provisioner for policyfiles w/ chef zero [\#260](https://github.com/chef/chef-dk/pull/260) ([danielsdeleo](https://github.com/danielsdeleo))
- For knife spork, we need to run rake, not rake test [\#259](https://github.com/chef/chef-dk/pull/259) ([jaym](https://github.com/jaym))
- Use File::PATH\_SEPARATOR for GEM\_PATH [\#257](https://github.com/chef/chef-dk/pull/257) ([jaym](https://github.com/jaym))
- Pass version to command when execing [\#255](https://github.com/chef/chef-dk/pull/255) ([jaym](https://github.com/jaym))
- Consistent quoting for exports [\#254](https://github.com/chef/chef-dk/pull/254) ([jaym](https://github.com/jaym))
- Adding powershell to chef shell-init [\#253](https://github.com/chef/chef-dk/pull/253) ([jaym](https://github.com/jaym))
- Export Policyfile as Chef Zero-compatible repo [\#249](https://github.com/chef/chef-dk/pull/249) ([danielsdeleo](https://github.com/danielsdeleo))
- Show the path checked on MissingComponentError [\#245](https://github.com/chef/chef-dk/pull/245) ([jaym](https://github.com/jaym))
- Add verification of linked scripts on \*nix [\#243](https://github.com/chef/chef-dk/pull/243) ([danielsdeleo](https://github.com/danielsdeleo))
- Add support for a Windows environment without true/false [\#240](https://github.com/chef/chef-dk/pull/240) ([btm](https://github.com/btm))
- Added fauxhai, rubocop, knife-spork, and kitchen-vagrant to verify [\#235](https://github.com/chef/chef-dk/pull/235) ([jaym](https://github.com/jaym))

## [0.3.5](https://github.com/chef/chef-dk/tree/0.3.5) (2014-11-13)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.3.4...0.3.5)

**Closed issues:**

- `chef shell-init` emits warnings on stdout, preventing the use of bash `eval` [\#229](https://github.com/chef/chef-dk/issues/229)
- chefdk 0.3.3 Ubuntu and Debian packages have broken chef\* scripts [\#228](https://github.com/chef/chef-dk/issues/228)
- chefdk is still in `gem env` after uninstalling it [\#223](https://github.com/chef/chef-dk/issues/223)
- Incompatible bundler version when using test-kitchen with vagrant driver [\#218](https://github.com/chef/chef-dk/issues/218)

**Merged pull requests:**

- Pulled in fix for joining paths on windows [\#232](https://github.com/chef/chef-dk/pull/232) ([jaym](https://github.com/jaym))
- Emit PATH warnings to stderr instead of stdout [\#231](https://github.com/chef/chef-dk/pull/231) ([danielsdeleo](https://github.com/danielsdeleo))
- Various changes to get specs to pass on windows [\#225](https://github.com/chef/chef-dk/pull/225) ([jaym](https://github.com/jaym))

## [0.3.4](https://github.com/chef/chef-dk/tree/0.3.4) (2014-11-12)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.3.3...0.3.4)

**Merged pull requests:**

- Update Changelog for 0.3.4, bump version [\#230](https://github.com/chef/chef-dk/pull/230) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.3.3](https://github.com/chef/chef-dk/tree/0.3.3) (2014-11-12)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.3.2...0.3.3)

**Implemented enhancements:**

- code\_generator kitchen.yml.erb is out-of-date \(centos-6.4\) [\#177](https://github.com/chef/chef-dk/issues/177)
- Add `--generator-arg` option to generator base [\#217](https://github.com/chef/chef-dk/pull/217) ([martinb3](https://github.com/martinb3))

**Fixed bugs:**

- chef push got 400 "Bad Request" from Enterprise Chef 12.0.0.rc5 and 11.1.3 [\#208](https://github.com/chef/chef-dk/issues/208)
- Berks install fails on Windows with SSL v3 verify error [\#199](https://github.com/chef/chef-dk/issues/199)
- Windows chefdk 0.1.1 verify failing when run in base directory [\#102](https://github.com/chef/chef-dk/issues/102)
- Input/output error on Windows when trying to converge with test-kitchen [\#89](https://github.com/chef/chef-dk/issues/89)
- Windows can't install into anything other than C:\opscode [\#68](https://github.com/chef/chef-dk/issues/68)

**Closed issues:**

- Move 'rspec' to /opt/chef/bin [\#215](https://github.com/chef/chef-dk/issues/215)
- ChefDK 0.3.2 still ships chef-client 11.16.0 [\#213](https://github.com/chef/chef-dk/issues/213)
- chef generate should accept arbitrary attribute data like chef-client and other tools [\#210](https://github.com/chef/chef-dk/issues/210)
- RspecJunitFormatter gem Conflict  [\#209](https://github.com/chef/chef-dk/issues/209)
- Berks Install fails on OS X 10.10 with SSL V3 verify error. [\#205](https://github.com/chef/chef-dk/issues/205)
- Bump the version of Ridley and Berkshelf [\#204](https://github.com/chef/chef-dk/issues/204)
- Please provide more info on ChefDK package updates [\#203](https://github.com/chef/chef-dk/issues/203)
- Problem with Test-Ketchen and EC2 [\#105](https://github.com/chef/chef-dk/issues/105)

**Merged pull requests:**

- Don't treat git local remotes as "remote" [\#241](https://github.com/chef/chef-dk/pull/241) ([danielsdeleo](https://github.com/danielsdeleo))
- Bump version and update changelog for 0.3.3 [\#226](https://github.com/chef/chef-dk/pull/226) ([danielsdeleo](https://github.com/danielsdeleo))
- Allow prereleases to be included in the chefdk [\#224](https://github.com/chef/chef-dk/pull/224) ([jkeiser](https://github.com/jkeiser))
- Check deeper directories for .git when selecting a SCM profiler [\#220](https://github.com/chef/chef-dk/pull/220) ([danielsdeleo](https://github.com/danielsdeleo))
- Add changelog entry for \#217 [\#219](https://github.com/chef/chef-dk/pull/219) ([danielsdeleo](https://github.com/danielsdeleo))
- Fixup erchef API errors [\#216](https://github.com/chef/chef-dk/pull/216) ([danielsdeleo](https://github.com/danielsdeleo))
- Improve Debug for Policyfile Commands [\#214](https://github.com/chef/chef-dk/pull/214) ([danielsdeleo](https://github.com/danielsdeleo))
- Update code\_generator template to latest centos [\#212](https://github.com/chef/chef-dk/pull/212) ([martinb3](https://github.com/martinb3))

## [0.3.2](https://github.com/chef/chef-dk/tree/0.3.2) (2014-10-28)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.3.1...0.3.2)

**Closed issues:**

- chefDK embedded ruby path is behind chef embedded [\#206](https://github.com/chef/chef-dk/issues/206)

**Merged pull requests:**

- Update changelog and version for 0.3.2 [\#207](https://github.com/chef/chef-dk/pull/207) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.3.1](https://github.com/chef/chef-dk/tree/0.3.1) (2014-10-23)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.3.0...0.3.1)

**Closed issues:**

- chef gem install still installs to user's ~/.chefdk [\#198](https://github.com/chef/chef-dk/issues/198)
- upgrading to 0.3.0-1 breaks berks install in chefspecs [\#197](https://github.com/chef/chef-dk/issues/197)
- chef-dk eclipse plugin [\#196](https://github.com/chef/chef-dk/issues/196)
- Gem conflicts archive libarchive-ruby [\#195](https://github.com/chef/chef-dk/issues/195)
- Hitimes extension error [\#192](https://github.com/chef/chef-dk/issues/192)
- Digest::Base cannot be directly inherited in Ruby \(RuntimeError\) [\#191](https://github.com/chef/chef-dk/issues/191)
- ChefDK Download Page Causing Reload/Redirect Loop [\#179](https://github.com/chef/chef-dk/issues/179)
- knife cookbook test -o on windows failing do to : seporator [\#178](https://github.com/chef/chef-dk/issues/178)

**Merged pull requests:**

- Update version and changelog for 0.3.1 [\#202](https://github.com/chef/chef-dk/pull/202) ([danielsdeleo](https://github.com/danielsdeleo))
- Add short description of Policyfile syntax [\#200](https://github.com/chef/chef-dk/pull/200) ([danielsdeleo](https://github.com/danielsdeleo))
- Add policyfile generator [\#189](https://github.com/chef/chef-dk/pull/189) ([danielsdeleo](https://github.com/danielsdeleo))
- Skip PATH sanity tests outside of omnibus [\#188](https://github.com/chef/chef-dk/pull/188) ([danielsdeleo](https://github.com/danielsdeleo))
- DRY Policyfile and lock file path munging [\#185](https://github.com/chef/chef-dk/pull/185) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.3.0](https://github.com/chef/chef-dk/tree/0.3.0) (2014-10-01)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.2.2...0.3.0)

**Fixed bugs:**

- chef dk install panel incomplete install path [\#161](https://github.com/chef/chef-dk/issues/161)
- Error using embedded knife/chef-zero when creating environment [\#159](https://github.com/chef/chef-dk/issues/159)
- Foodcritic not running correctly after installing 0.2.2 msi on windows 7 [\#165](https://github.com/chef/chef-dk/issues/165)
- New install of ChefDK 0.2.1 on Mac OS X 10.9.4 - Appears to fail - not really though [\#158](https://github.com/chef/chef-dk/issues/158)
- Move git\_init check into it's own block under have\_git [\#147](https://github.com/chef/chef-dk/pull/147) ([tbunnyman](https://github.com/tbunnyman))

**Closed issues:**

- ChefDK installation on Windows disregards target drive on scripts in chefdk/bin folder [\#170](https://github.com/chef/chef-dk/issues/170)
- 0.2.2: knife and kitchen complaining about eventmachine-1.0.3 [\#169](https://github.com/chef/chef-dk/issues/169)
- Build chef-dk from source [\#166](https://github.com/chef/chef-dk/issues/166)
- chef gem install pulls in ri and rdoc [\#164](https://github.com/chef/chef-dk/issues/164)
- 0.2.2 knife still uses 12.0.0.alpha.1 [\#162](https://github.com/chef/chef-dk/issues/162)
- bundle install requires sudo / root password or --path? [\#148](https://github.com/chef/chef-dk/issues/148)
- Support chef-dk on Linux Debian Wheezy \(aka Debian 7.x\) [\#51](https://github.com/chef/chef-dk/issues/51)
- WARN users when their PATH includes embedded first [\#163](https://github.com/chef/chef-dk/issues/163)

**Merged pull requests:**

- Bump version and update CHANGELOG.md. [\#176](https://github.com/chef/chef-dk/pull/176) ([sersut](https://github.com/sersut))
- add warnings for bad PATH settings [\#175](https://github.com/chef/chef-dk/pull/175) ([lamont-granquist](https://github.com/lamont-granquist))
- Contribution info for 0.3.0 contributions. [\#174](https://github.com/chef/chef-dk/pull/174) ([sersut](https://github.com/sersut))
- add changelog for ruby 2.1.3 version bump [\#172](https://github.com/chef/chef-dk/pull/172) ([lamont-granquist](https://github.com/lamont-granquist))
- Extract Table Printing Logic [\#167](https://github.com/chef/chef-dk/pull/167) ([danielsdeleo](https://github.com/danielsdeleo))
- Set GEM\_HOME to Gem.user\_dir instead of Gem.paths.home [\#160](https://github.com/chef/chef-dk/pull/160) ([rberger](https://github.com/rberger))
- Policyfile CLI [\#157](https://github.com/chef/chef-dk/pull/157) ([danielsdeleo](https://github.com/danielsdeleo))
- Update README.md [\#151](https://github.com/chef/chef-dk/pull/151) ([AnalogJ](https://github.com/AnalogJ))
- Gracefully handle invalid CLI options [\#173](https://github.com/chef/chef-dk/pull/173) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.2.2](https://github.com/chef/chef-dk/tree/0.2.2) (2014-09-10)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.2.1...0.2.2)

**Fixed bugs:**

- Error messages when doing `chef gem list` [\#146](https://github.com/chef/chef-dk/issues/146)
- Error messages when doing `chef gem list` [\#146](https://github.com/chef/chef-dk/issues/146)
- Berkshelf SSL\_connect error on Windows: certificate verify failed [\#106](https://github.com/chef/chef-dk/issues/106)

**Closed issues:**

- ChefDK 0.2.1 on Windows defaults to using chef 12.0.0.alpha.1, inconsistent with Mac/Linux [\#156](https://github.com/chef/chef-dk/issues/156)
- `chef exec rspec` fails with 'Permission denied @ dir\_s\_mkdir' [\#135](https://github.com/chef/chef-dk/issues/135)

**Merged pull requests:**

- Make sure the context is set right while generating a template. [\#149](https://github.com/chef/chef-dk/pull/149) ([sersut](https://github.com/sersut))

## [0.2.1](https://github.com/chef/chef-dk/tree/0.2.1) (2014-08-27)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.2.0...0.2.1)

**Implemented enhancements:**

- Make adding generators a bit easier [\#116](https://github.com/chef/chef-dk/issues/116)
- Support chef-dk on Mac OSX 10.8  [\#14](https://github.com/chef/chef-dk/issues/14)

**Fixed bugs:**

- knife and berks create many temp directories [\#133](https://github.com/chef/chef-dk/issues/133)
- Installing gems to profile directory on Windows breaks when username has a space in it [\#129](https://github.com/chef/chef-dk/issues/129)
- Chef generate app directory confusion ! [\#111](https://github.com/chef/chef-dk/issues/111)
- devkit is broken on windows [\#100](https://github.com/chef/chef-dk/issues/100)
- Supermarket is live, use it for Berks source [\#112](https://github.com/chef/chef-dk/pull/112) ([jtimberman](https://github.com/jtimberman))

**Closed issues:**

- Need to update Berkshelf to at least 3.1.5 [\#141](https://github.com/chef/chef-dk/issues/141)
- Foodcritic not working on Windows when installed with Chef-DK [\#139](https://github.com/chef/chef-dk/issues/139)
- Chef exec, Chefspec and Rake.  [\#137](https://github.com/chef/chef-dk/issues/137)
- provide i686 packages and support ubuntu 14.04 [\#132](https://github.com/chef/chef-dk/issues/132)
- Incorrect permissions on files in ubuntu package [\#130](https://github.com/chef/chef-dk/issues/130)
- Upgrade foodcritic [\#128](https://github.com/chef/chef-dk/issues/128)
- Multiple versions of chef client installed [\#127](https://github.com/chef/chef-dk/issues/127)
- semverse stack level too deep with berkshelf 3.1.1 [\#126](https://github.com/chef/chef-dk/issues/126)
- chef exec rake fails on Ubuntu 14.04 [\#125](https://github.com/chef/chef-dk/issues/125)
- foodcritic fails on freshly installed ChefDK windows [\#124](https://github.com/chef/chef-dk/issues/124)
- chef exec rake fails on osx mavericks \(segfault\) [\#123](https://github.com/chef/chef-dk/issues/123)
- chefdk 0.2.0 doesnt pretty print json objects anymore [\#121](https://github.com/chef/chef-dk/issues/121)
- `chef generate cookbook` should not require elevated privileges on Windows [\#109](https://github.com/chef/chef-dk/issues/109)
- chef exec rspec not working [\#103](https://github.com/chef/chef-dk/issues/103)
- chef-dk 0.1.0-1 defaults to attempting to download nonexistent chef 11.14.0-alpha-1 during bootstrap [\#96](https://github.com/chef/chef-dk/issues/96)
- Run 'make clean' in depselector-libgecode vendor directory [\#92](https://github.com/chef/chef-dk/issues/92)

**Merged pull requests:**

- Version bump and rel info for 0.2.1. [\#143](https://github.com/chef/chef-dk/pull/143) ([sersut](https://github.com/sersut))
- Add validation of Policyfile.lock data structures when ingesting [\#142](https://github.com/chef/chef-dk/pull/142) ([danielsdeleo](https://github.com/danielsdeleo))
- Validate source options for cookbooks [\#138](https://github.com/chef/chef-dk/pull/138) ([danielsdeleo](https://github.com/danielsdeleo))
- Disable atomic file updates on Windows [\#134](https://github.com/chef/chef-dk/pull/134) ([btm](https://github.com/btm))
- Removes ignoring of CHANGELOG [\#131](https://github.com/chef/chef-dk/pull/131) ([cwebberOps](https://github.com/cwebberOps))
- Add a description of policyfile design and status [\#122](https://github.com/chef/chef-dk/pull/122) ([danielsdeleo](https://github.com/danielsdeleo))
- Detect Cookbook Changes and enable auto-updating of the Policyfile.lock.json [\#120](https://github.com/chef/chef-dk/pull/120) ([danielsdeleo](https://github.com/danielsdeleo))
- Upload Cookbooks Specified in Lockfile [\#119](https://github.com/chef/chef-dk/pull/119) ([danielsdeleo](https://github.com/danielsdeleo))
- Easy generators [\#118](https://github.com/chef/chef-dk/pull/118) ([adamhjk](https://github.com/adamhjk))
- Adds chef generate repo support [\#117](https://github.com/chef/chef-dk/pull/117) ([adamhjk](https://github.com/adamhjk))
- add create\_if\_missing to files which will be customized [\#115](https://github.com/chef/chef-dk/pull/115) ([lamont-granquist](https://github.com/lamont-granquist))
- Break generator commands into seperate files [\#114](https://github.com/chef/chef-dk/pull/114) ([adamhjk](https://github.com/adamhjk))
- use ChefDK instead of Chef DK [\#110](https://github.com/chef/chef-dk/pull/110) ([smith](https://github.com/smith))
- Set environment before exec to ensure PATH takes effect [\#104](https://github.com/chef/chef-dk/pull/104) ([danielsdeleo](https://github.com/danielsdeleo))
- adding smoke and unit test for chefspec [\#101](https://github.com/chef/chef-dk/pull/101) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/rspec 3 [\#99](https://github.com/chef/chef-dk/pull/99) ([lamont-granquist](https://github.com/lamont-granquist))
- debugger/pry-debugger no likey ruby 2.1.x [\#98](https://github.com/chef/chef-dk/pull/98) ([lamont-granquist](https://github.com/lamont-granquist))

## [0.2.0](https://github.com/chef/chef-dk/tree/0.2.0) (2014-07-09)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.1.1...0.2.0)

**Implemented enhancements:**

- Prefetch fixed cookbooks [\#80](https://github.com/chef/chef-dk/pull/80) ([danielsdeleo](https://github.com/danielsdeleo))
- Initial specification of policyfile builder [\#53](https://github.com/chef/chef-dk/pull/53) ([danielsdeleo](https://github.com/danielsdeleo))

**Fixed bugs:**

- Chef Client binaries fail with dyld: lazy symbol binding failed: Symbol not found: \_yajl\_alloc [\#82](https://github.com/chef/chef-dk/issues/82)
- chef-solo from chefdk slow to run at startup. Not sure how to troubleshoot [\#77](https://github.com/chef/chef-dk/issues/77)
- New build of ChefDK against new net-ssh [\#75](https://github.com/chef/chef-dk/issues/75)
- Windows chef-dk alpha is very large. [\#70](https://github.com/chef/chef-dk/issues/70)
- Windows: "DL is deprecated, please use Fiddle" [\#69](https://github.com/chef/chef-dk/issues/69)
- Windows installer defects [\#67](https://github.com/chef/chef-dk/issues/67)
- ohai should be runnable after installing Chef DK [\#60](https://github.com/chef/chef-dk/issues/60)
- Collect the low hanging fruits in order to reduce the package size of Chef DK [\#59](https://github.com/chef/chef-dk/issues/59)
- chef gem install \<gemname\> --version displays chefDK version [\#46](https://github.com/chef/chef-dk/issues/46)
- Chef Verify Failures on Windows [\#43](https://github.com/chef/chef-dk/issues/43)
- Handle GemRunner returning nil on success [\#57](https://github.com/chef/chef-dk/pull/57) ([mpasternacki](https://github.com/mpasternacki))
- Avoid appending a double ".erb" in templates [\#54](https://github.com/chef/chef-dk/pull/54) ([David-Gil](https://github.com/David-Gil))

**Closed issues:**

- Link to Learn Chef site in the README [\#93](https://github.com/chef/chef-dk/issues/93)
- default recipe in generated kitchen.yml file does not match name of default cookbook [\#85](https://github.com/chef/chef-dk/issues/85)
- ChefDK comes with broken tar.exe [\#84](https://github.com/chef/chef-dk/issues/84)
- Calling knife returns 'Could not locate Gemfile' message [\#79](https://github.com/chef/chef-dk/issues/79)
- Can't run ChefSpec with ChefDK \(Windows Alpha\)?! [\#78](https://github.com/chef/chef-dk/issues/78)
- make the 'knife' that runs in chef-dk a released version so bootstrap doesn't explode [\#74](https://github.com/chef/chef-dk/issues/74)
- chef-dk 0.1.0-1 bundled ruby is linked against libc 2.17 or later. [\#56](https://github.com/chef/chef-dk/issues/56)
- Document how to uninstall chefdk [\#17](https://github.com/chef/chef-dk/issues/17)

**Merged pull requests:**

- Version bump for 0.2.0 release and updated change log. [\#95](https://github.com/chef/chef-dk/pull/95) ([sersut](https://github.com/sersut))
- Add link to Learn Chef [\#94](https://github.com/chef/chef-dk/pull/94) ([nathenharvey](https://github.com/nathenharvey))
- Bump chef to latest RC for chef dk. [\#90](https://github.com/chef/chef-dk/pull/90) ([sersut](https://github.com/sersut))
- switch to using chef-zero instead of chef-solo [\#88](https://github.com/chef/chef-dk/pull/88) ([lamont-granquist](https://github.com/lamont-granquist))
- Cache community coookbooks [\#87](https://github.com/chef/chef-dk/pull/87) ([danielsdeleo](https://github.com/danielsdeleo))
- Make `chef generate app` set cookbook name [\#86](https://github.com/chef/chef-dk/pull/86) ([mcquin](https://github.com/mcquin))
- Fix appending .erb to template filename. [\#83](https://github.com/chef/chef-dk/pull/83) ([mcquin](https://github.com/mcquin))
- Uninstall instructions for Chef DK.  [\#81](https://github.com/chef/chef-dk/pull/81) ([sersut](https://github.com/sersut))
- Pin chef in the Gemfile instead of gemspec. [\#76](https://github.com/chef/chef-dk/pull/76) ([sersut](https://github.com/sersut))
- Policyfile solve graph [\#73](https://github.com/chef/chef-dk/pull/73) ([danielsdeleo](https://github.com/danielsdeleo))
- Pin chef to a version that supports Windows with Ruby 2.0. [\#66](https://github.com/chef/chef-dk/pull/66) ([sersut](https://github.com/sersut))
- Cleanup the README links and language [\#65](https://github.com/chef/chef-dk/pull/65) ([sethvargo](https://github.com/sethvargo))
- Suggest `exec` and `shell-init` to run commands from gems [\#64](https://github.com/chef/chef-dk/pull/64) ([danielsdeleo](https://github.com/danielsdeleo))
- Add `shell-init` command. [\#63](https://github.com/chef/chef-dk/pull/63) ([danielsdeleo](https://github.com/danielsdeleo))
- Implement Policyfile evaluation [\#61](https://github.com/chef/chef-dk/pull/61) ([danielsdeleo](https://github.com/danielsdeleo))
- install specific gem version [\#55](https://github.com/chef/chef-dk/pull/55) ([mcquin](https://github.com/mcquin))
- Remove cookbooks folder from gitignore skeleton [\#49](https://github.com/chef/chef-dk/pull/49) ([David-Gil](https://github.com/David-Gil))

## [0.1.1](https://github.com/chef/chef-dk/tree/0.1.1) (2014-05-14)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.1.0...0.1.1)

**Implemented enhancements:**

- Add skeleton option for chef generate [\#40](https://github.com/chef/chef-dk/pull/40) ([martinisoft](https://github.com/martinisoft))

**Fixed bugs:**

- chef-apply requires privileged access to run [\#42](https://github.com/chef/chef-dk/issues/42)
- Symlink to chef-zero is not created on Debian/Ubuntu in /usr/bin [\#35](https://github.com/chef/chef-dk/issues/35)
- Can't run chef generate cookbook with an existing cookbook [\#12](https://github.com/chef/chef-dk/issues/12)

**Closed issues:**

- ChefDK fails on windows due to Chef incompatibility with ruby 2.0 [\#41](https://github.com/chef/chef-dk/issues/41)
- embedded rubocop out of date [\#39](https://github.com/chef/chef-dk/issues/39)
- failing to install knife-ec2 in Chef-DK embedded setup [\#36](https://github.com/chef/chef-dk/issues/36)
- Chef DK and OpenSSL w/ Open Source Chef Server [\#34](https://github.com/chef/chef-dk/issues/34)
- Knife error -  `parse': '11.14.0.alpha.1' does not match 'x.y.z' or 'x.y' \(Chef::Exceptions::InvalidCookbookVersion\) [\#32](https://github.com/chef/chef-dk/issues/32)
- Can't seem to install with brew cask [\#30](https://github.com/chef/chef-dk/issues/30)
- Add file to enable vendoring chef-dk and required gems within the chef-dk ruby instance [\#27](https://github.com/chef/chef-dk/issues/27)

**Merged pull requests:**

- Remove shell scripts from tests [\#47](https://github.com/chef/chef-dk/pull/47) ([danielsdeleo](https://github.com/danielsdeleo))
- Verify fixes for windows [\#45](https://github.com/chef/chef-dk/pull/45) ([danielsdeleo](https://github.com/danielsdeleo))
- whoops, forgot chef exec docs [\#38](https://github.com/chef/chef-dk/pull/38) ([lamont-granquist](https://github.com/lamont-granquist))
- don't print help after successful command [\#33](https://github.com/chef/chef-dk/pull/33) ([mcquin](https://github.com/mcquin))
- Import 0.1.0 Release notes to changelog [\#31](https://github.com/chef/chef-dk/pull/31) ([danielsdeleo](https://github.com/danielsdeleo))
- tests don't write to spec/unit [\#29](https://github.com/chef/chef-dk/pull/29) ([mcquin](https://github.com/mcquin))
- Utilize TemplateHelper for README.md, kitchen.yml [\#28](https://github.com/chef/chef-dk/pull/28) ([ghost](https://github.com/ghost))
- add chef exec command [\#22](https://github.com/chef/chef-dk/pull/22) ([lamont-granquist](https://github.com/lamont-granquist))

## [0.1.0](https://github.com/chef/chef-dk/tree/0.1.0) (2014-04-28)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.0.1...0.1.0)

**Implemented enhancements:**

- `chef verify` doesn't work as non-root [\#13](https://github.com/chef/chef-dk/issues/13)
- run as a normal user, chef gem install should install gems to a writable location [\#11](https://github.com/chef/chef-dk/issues/11)

**Closed issues:**

- permissions end up incorrect after install chef-dk on MacOS X [\#19](https://github.com/chef/chef-dk/issues/19)
- Creating a new chef binary is unhelpful [\#7](https://github.com/chef/chef-dk/issues/7)
- README could be more helpful [\#24](https://github.com/chef/chef-dk/issues/24)
- `chef verify` on new OSX install fails [\#21](https://github.com/chef/chef-dk/issues/21)
- Unable to run `kitchen init` [\#20](https://github.com/chef/chef-dk/issues/20)
- How does ChefDK interoperate \(or break\) normal ruby gem workflows? [\#16](https://github.com/chef/chef-dk/issues/16)
- kitchen-vagrant missing when installing chef-dk from dmg [\#15](https://github.com/chef/chef-dk/issues/15)

**Merged pull requests:**

- omit @graphviz tagged cucumber test in berks [\#26](https://github.com/chef/chef-dk/pull/26) ([mcquin](https://github.com/mcquin))
- Improved Verify [\#25](https://github.com/chef/chef-dk/pull/25) ([danielsdeleo](https://github.com/danielsdeleo))
- exclude graphviz tags from berks tests [\#23](https://github.com/chef/chef-dk/pull/23) ([mcquin](https://github.com/mcquin))

## [0.0.1](https://github.com/chef/chef-dk/tree/0.0.1) (2014-04-15)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.0.1.alpha.1...0.0.1)

## [0.0.1.alpha.1](https://github.com/chef/chef-dk/tree/0.0.1.alpha.1) (2014-04-12)
[Full Changelog](https://github.com/chef/chef-dk/compare/0.0.1.alpha.0...0.0.1.alpha.1)

**Merged pull requests:**

- Disable @spawn tests on berks to unblock chefdk releases.  [\#9](https://github.com/chef/chef-dk/pull/9) ([sersut](https://github.com/sersut))
- Update shellout to 1.4.0; Update chef to release version [\#8](https://github.com/chef/chef-dk/pull/8) ([danielsdeleo](https://github.com/danielsdeleo))

## [0.0.1.alpha.0](https://github.com/chef/chef-dk/tree/0.0.1.alpha.0) (2014-04-09)
**Merged pull requests:**

- CC-44: Verify chef-dk gem during "chef verify" [\#6](https://github.com/chef/chef-dk/pull/6) ([sersut](https://github.com/sersut))
- Use chef as our code generator [\#5](https://github.com/chef/chef-dk/pull/5) ([danielsdeleo](https://github.com/danielsdeleo))
- Verify command for chef which runs the specs for the components. [\#4](https://github.com/chef/chef-dk/pull/4) ([sersut](https://github.com/sersut))
- Rework the command loader to be as lazy as possible [\#3](https://github.com/chef/chef-dk/pull/3) ([danielsdeleo](https://github.com/danielsdeleo))
- Add a simple gem command to install to the bundled gems [\#2](https://github.com/chef/chef-dk/pull/2) ([danielsdeleo](https://github.com/danielsdeleo))
- CC-14: Create chef-dk gem [\#1](https://github.com/chef/chef-dk/pull/1) ([sersut](https://github.com/sersut))
