# `chef provision` Command README

`chef provision` invokes an embedded chef-client run to provision machines
using Chef Provisioning. If not otherwise specified, `chef provision` will
expect to find a cookbook named 'provision' in the current working directory.
It runs a recipe in this cookbook which should use Chef Provisioning to create
one or more machines (or other infrastructure).

The `chef provision` command aims to achieve these goals:

* Provide provisioning mechanism that supports Policyfiles
* Improve Chef Provisioning ease of use by creating naming conventions
* Improve Chef Provisioning ease of use by integrating with ChefDK CLI
* Improve Chef Provisioning ease of use by separating the way you
  configure provisioned machines from the way you invoke Chef
  Provisioning
* Improve on the `knife bootstrap` experience by expressing more of your
  provisioning requirements as code (instead of CLI options).

## Basic CLI Use

`chef provision` provides three forms of operation:

### chef provision POLICY_GROUP --policy-name POLICY_NAME

In the first form of the command, `chef provision` creates machines that will
operate in policyfile mode. The chef configuration passed to the cookbook will
set the policy group and policy name as given.

### chef provision POLICY_GROUP --sync [POLICYFILE_PATH] [options]

In the second form of the command, `chef provision` create machines that will
operate in policyfile mode and syncronizes a local policyfile to the server
before converging the machine(s) defined in the provision cookbook.

### chef provision --no-policy [options]

In the third form of the command, `chef provision` expects to create machines
that will not operate in policyfile mode.

Note that this command is considered beta. Behavior, the APIs that pass CLI
data to chef-client, and argument names may change as more experience is gained
from real-world usage.

## Cookbook Integration

Most of the options and arguments to `chef provision` only affect what
default data is passed to your provisioning recipe. Your recipe must
pull data from the provisioning data context in order for the command
line values to have any effect on the provisioned machines.

### Basic Example

This is a machine recipe I created to demonstrate provisioning with
Policyfiles:

```ruby
# Assign the context to a local variable for convenience
context = ChefDK::ProvisioningData.context

with_driver 'vagrant:~/.vagrant.d/boxes' do

  # Set Machine Options
  options = {
    vagrant_options: { 'vm.box' => 'opscode-ubuntu-14.04' },
    # Set all machine options to the defaults provided by `chef provision`
    convergence_options: context.convergence_options
  }


  # Set node_name to user provided node name
  machine context.node_name do
    machine_options(options)

    # This forces a chef run every time, which is sensible for some
    # `chef provision` use cases, especially when using `--sync`
    converge(true)
    # Set action to what `chef provision` specifies
    action(context.action)
  end
end
```

To provision the machine, I run:

```sh
chef provision test123 --sync -n aar-dev
```

This synchronizes my Policyfile lock to my Chef Server and converges the
node.

### Provisioning Context

The provisioning context provides the following data:

* `action`: `:converge`, or `:destroy` if you pass `-d` to the
  CLI.
* `node_name`: the argument to the `-n` option.
* `target`: the argument to the `-t` option. This is probably most
  useful when using provisioning's SSH driver to converge existing
  hosts.
* `opts`: contains arbitrary user-defined options set via the `-o`
  option. For example, given a command line including `-o foo=bar` you
  would access the command line option via:

```ruby
context = ChefDK::ProvisioningData.context
context.opts.foo
# => "bar"
```

* `policy_group`: is set to the relevant CLI argument when operating in
  one of the Policyfile modes.
* `policy_name`: set to either the value of `--policy-name` or the
  policy name specified in the Policyfile lock for `--sync`
* `extra_chef_config`: `chef provision` currently uses the `chef_config`
  convergence option to set Policyfile config and duplicate your current
  `ssl_verify_mode` setting. You can set further custom config by
  assigning a value to this setting, e.g.:

```ruby
ChefDK::ProvisioningData.context.extra_chef_config = 'log_level :debug'
```

