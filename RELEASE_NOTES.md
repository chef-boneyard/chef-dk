# ChefDK 1.1 Release notes

## New Inspec Test Location
To address bugs and confusion with the previous `test/recipes` location, all newly generated
cookbooks and recipes will place their Inspec tests in `test/smoke/default`. This
placement creates the association of the `smoke` Workflow phase and the `default` Kitchen suite
where the tests are run.

## Default Docker image in kitchen-dokken is now official Chef image
[chef/chef](https://hub.docker.com/r/chef/chef) is now the default Docker image used in
[kitchen-dokken](https://github.com/someara/kitchen-dokken).

## New Kitchen driver caching mechanisms
Kitchen will automatically cache downloaded chef-client packages for use between provisions.
For people who use the `kitchen-vagrant` driver to run Chef, it will automatically consume the
new caching mechanism to share the client packages to the guest VM, meaning that you no longer
have to wait for the client to download on every guest provision.

In addition, if the chef-client packages are already cached, then it is now possible to use
Kitchen completely off-line.

## Cookstyle 1.1.0 with new code linting Cops

Cookstyle has been updated from `0.0.1` to `1.1.0`, which upgrades the RuboCop engine from `0.39`
to `0.46` and enables several new cops. This will most likely result in Cookstyle warning on
cookbooks that previously passed.

### Newly Disabled Cops:

- Metrics/CyclomaticComplexity
- Style/NumericLiterals
- Style/RegexpLiteral in 'tests' directory
- Style/AsciiComments
- Style/TernaryParentheses
- Metrics/ClassLength
- All rails/* cops

### Newly Enabled Cops:

- Bundler/DuplicatedGem
- Style/SpaceInsideArrayPercentLiteral
- Style/NumericPredicate
- Style/EmptyCaseCondition
- Style/EachForSimpleLoop
- Style/PreferredHashMethods
- Lint/UnifiedInteger
- Lint/PercentSymbolArray
- Lint/PercentStringArray
- Lint/EmptyWhen
- Lint/EmptyExpression
- Lint/DuplicateCaseCondition
- Style/TrailingCommaInLiteral
- Lint/ShadowedException

## New DCO Tool Included

We have included a new dco command line tool that makes it easier to contribute to projects like
Chef that use the Developer Certificate of Origin. The tool allows you to enable/disable DCO
sign-offs on a per repository basis and also allows you to retroactively sign off all commits on
a branch. See https://github.com/coderanger/dco for details.

## Notable Upgraded Gems

- chef `12.16.42` -> `12.17.44`
- ohai `8.21.0` -> `8.22.0`
- inspec `1.4.1` -> `1.7.2`
- train `0.21.1` -> `0.22.0`
- test-kitchen `1.13.2` -> `1.14.2`
- kitchen-vagrant `0.20.0` -> `0.21.1`
- winrm-elevated `1.0.1` -> `1.1.0`
- winrm-fs `1.0.0` -> `1.0.1`
- cookstyle `0.0.1` -> `1.1.0`
