# ChefDK Policyfile  README

## What's this Policyfile Stuff?

First of all, it's alpha-quality software. Though one of our goals is to
make Chef a lot easier to get started with, it's definitely not a good
idea to start using it if you're new to Chef. If you're an experienced
user, we'd love for you to use it and provide feedback, but BEWARE: you
are strongly advised to use this only with a separate Chef Server or
Enterprise Chef organization. To be compatible with the currrent Chef
Server feature set, policyfile commands will do things like upload
cookbooks with very large, non-sequential, version numbers (more detail
on this below). Unless you've taken a specific precautions, you can
easily hurt yourself by running Policyfile commands against a production
Chef Server (or organization).

If you try it out and have any feedback, first check out whether it's
listed in the "Known Limitations" section below. If your idea/need isn't
listed there, or if you encounter a bug, file an issue at https://github.com/opscode/chef-dk/issues

## Ok, I've Been Warned. What Is It?

One last warning: This section of the document describes features that
don't exist yet as if they do exist. The "Known Limitations" section
lists the features that are not yet complete.

The Policyfile is a Chef feature that allows you to specify precisely
which cookbook revisions `chef-client` should use, and which recipes
should be applied, via a single document. This document is uploaded to
the Chef Server, where it is associated with a group of nodes. When
these nodes run `chef-client` they fetch the cookbooks specified by the
policyfile, and run the recipes specified by the policyfile's run list.
A given revision of a policyfile can be promoted through deployment
stages to safely and reliably deploy new configuration to your
infrastructure.

A `Policyfile.rb` is a Ruby DSL where you specify a `run_list` and tell
ChefDK where to find the cookbooks. It looks like this:

```ruby
# Policyfile.rb
name "jenkins"

default_source :community

run_list "java", "jenkins::master", "recipe[policyfile_demo]"

cookbook "policyfile_demo", path: "cookbooks/policyfile_demo"
```

When you run a `chef install`, ChefDK caches any necessary cookbooks and
emits a `Policyfile.lock.json` that describes the versions of cookbooks
in use, a hash of the cookbooks' content, the cookbooks' sources, and
other relevant data. It looks like this (content snipped for brevity):

```json
{
  "name": "jenkins",
  "run_list": [
    "recipe[java::default]",
    "recipe[jenkins::master]",
    "recipe[policyfile_demo::default]"
  ],
  "cookbook_locks": {
    "policyfile_demo": {
      "version": "0.1.0",
      "identifier": "f04cc40faf628253fe7d9566d66a1733fb1afbe9",
      "dotted_decimal_identifier": "67638399371010690.23642238397896298.25512023620585",
      "source": "cookbooks/policyfile_demo",
      "cache_key": null,
      "scm_info": null,
      "source_options": {
        "path": "cookbooks/policyfile_demo"
      }
    },
    "java": {
      "version": "1.24.0",
      "identifier": "4c24ae46a6633e424925c24e683e0f43786236a3",
      "dotted_decimal_identifier": "21432429158228798.18657774985439294.16782456927907",
      "cache_key": "java-1.24.0-supermarket.getchef.com",
      "origin": "https://supermarket.getchef.com/api/v1/cookbooks/java/versions/1.24.0/download",
      "source_options": {
        "artifactserver": "https://supermarket.getchef.com/api/v1/cookbooks/java/versions/1.24.0/download",
        "version": "1.24.0"
      }
```

You can then test this set of cookbooks in a VM or cloud instance. When
you're ready to run this policy on a set of nodes attached to your
server, you run the `chef push` command to push this revision of the
policy to a specific `policy group`. We've not yet designed any
specifics of how `policy groups` will be implemented, but the basic idea
is that you will configure your `chef-client` to use a policy like
"webapp" or "database" and belong to a `policy group` like "staging" or
"prod-cluster-1". Each policy group may have a different revision of
each policy, so that the "webapp" policy may have a different set of
cookbooks and different run list between the "staging" and
"prod-cluster-1" policy groups.

The `push` command will also upload cookbooks to a new cookbooks storage
API which stores them according to their identifiers, which in this
case are SHA-1 hashes of the cookbooks' content.

When `chef-client` runs, it reads its policy name and policy group from
configuration, and requests the current policy for its name and group
from the server. It then fetches the cookbooks from the new storage API,
and then proceeds as normal.

## Motivation and FAQ

### Focus Workflow on Configuring Machines to do Useful Work

Chef's current tooling (`knife` in particular) maps very closely to Chef
Server's REST API and therefore is centered around manipulating
individual objects and uploading them to the Chef Server. `chef-client`
assembles these pieces at run time (more on that below) to configure a
host to do some useful work for you organization. With the Policyfile
feature, we want to focus the workflow on creating and configuring
entire systems, rather than individual components. For example,
Policfiles describe whole systems and individual revisions of
`Policyfile.lock` documents are uploaded with all required components as
a unit to the Chef Server.

### Code Visibility

In Chef currently, the exact set of cookbooks that a node will apply is
defined by:

* The node's `run_list` property;
* Any roles present in the node's `run_list` or recursively included by
  those roles;
* The environment, which restricts the set of valid cookbook versions
available to a particular node according to a variety of constraint
operators;
* Dependencies specified in cookbook metadata;
* The dependency solver implementation, which tries to pick the "best"
set of cookbooks that meet the environment and dependency criteria.

These conditions are re-evaluated each time `chef-client` runs, so it's
not always easy to tell exactly which cookbooks `chef-client` will run,
or what the impact of updating a `role` or uploading a new cookbook will
be.

The Policyfile feature solves this problem by computing the cookbook set
on the workstation and producing a readable document of the solution.
`chef-client` runs re-use the same precomputed solution until you
explicitly update their specific policy group.

### Role Mutability

Roles are currently global objects and changes to existing roles are
applied immediately to all nodes that contain that role in their
`run_list` (either directly or via another role's `run_list`). This
means that updating existing roles can be very dangerous, so much so
that many users advocate abandoning them entirely.

The Policyfile feature improves the situation in two ways. Firstly,
roles are expanded at the time that the cookbook set is computed (i.e.,
the `chef install` step). Roles never appear in the
`Policyfile.lock.json` document. As a result, roles are "baked in" to a
particular revision of a policy, so that changes to a role can be tested
and rolled out gradually. Secondly, Policyfiles offer an alternative
means of managing the `run_list` for many nodes at once, since there is
a one-to-many relationship between policies and nodes. Therefore users
can, if desired, stop using roles without needing to use role cookbooks
as a workaround for managing the `run_list` of their nodes.

### Cookbook Mutability

The Chef Server currently allows an existing version of a cookbook to be
mutated. While this provides convenience for users who upload
in-development cookbook revisions to a Chef Server (this is common among
beginners and some Ci patterns), it offers the same problems as Role
mutability. Some users account for this by following a rigorous testing
process so that only fully integrated (i.e., all contributors' changes
are merged) and well tested cookbooks are ever published to the Chef
Server. While this process enforces good development habits, it is not
appropriate for everyone, and should not be a prerequisite for getting
safe behavior from the Chef Server.

The Policyfile feature solves this issue by using a new Chef Server
cookbook publishing API which does not provide cookbook mutability. In
order to avoid name collisions, cookbooks are stored by name and an
arbitrary ID, which is computed from the content of the cookbook itself.

One pesky example of name/version collisions is when users need to
temporarily use a fork of an upstream cookbook. Even if the user
contributes their change and the maintainer is very responsive, there
may be a period of time where the user needs to use their fork in order
to make progress. However, this presents a versioning quandry: if the
user doesn't update the version, they must overwrite the existing copy
of the cookbook on their server. Contrarily, if they do update the
version number, they might conflict with the version number of a future
release, which they could only fix by overwriting the newer version on
their server. Using content-based IDs with sourcing metadata makes this
use case easy.

#### But Opaque IDs are Confusing!

It's definitely true that such opaque IDs are less comfortable than the
name, version number scheme that users are used to. In order to
ameliorate the problem:

* When working with the `Policyfile.rb`, you deal with cookbooks
mostly in terms of names and version numbers. For cookbooks from an
artifact service like supermarket, you use names and version constraints
like you're used to; for cookbooks from git, you use branch/tag/revision
as you're used to; for cookbooks from disk, you specify paths. The
opaque IDs are mostly behind the scenes.
* Extra metadata about cookbooks is stored and included in API
responses, as well as the `Policyfile.lock.json`. This includes the
source of the cookbook (supermarket, git, local disk, etc.) and the
upstream ID of the cookbook (such as git revision); for cookbooks loaded
from local disk, the Policyfile implementation detects if they are in a
git repo and collects the upstream URL, current revision ID, whether the
repo is dirty, and whether the commits are pushed to the remote.
* Cookbooks uploaded to the new cookbook storage API can have extended
SemVer version numbers with prerelease sections, like `1.0.0-dev`.

### Limit Expensive Computation on Chef Server

In order to determine the cookbook set for a given chef-client run, Chef
Server has to load dependency data for all known versions of all
cookbooks, and then run an expensive (NP expensive) computation to
determine the correct set. Moving this computation to the workstation
and running it less frequently makes Chef Server more efficient.

### Where Does the Policyfile Live?

At the moment, we see three main ways to organize your Policyfiles:

* Store the Policyfile and related cookbooks in the same repository as
the application you're deploying. If you're deploying custom
applications written in-house and your software developers are
comfortable working with Chef, you can put the Policyfile in the same
repo as the application's source code and version everything together.
* Store the Policyfile with a cookbook. If you're following the single
cookbook per repo workflow, you can include the Policyfile in the
highest-level cookbook's (i.e., the cookbook ultimately responsible for
deploying a server's primary application) repository.
* Store all of your Policyfiles in a single directory. This is likely to
be the most common way to use Policyfiles with the monolithic cookbook
repo workflow. There are still some details to be worked out for this
case.

### Am I Going to be Forced to Use This?

This change will be rolled out by adding new functionality to Chef
Client, ChefDK, and Chef Server **alongside** the existing
functionality. There are no plans to remove or even deprecate the
existing APIs. The plan is to get people to switch by offering an
alternative with both more safety and more freedom than the current
situation.

That said, if adoption is large enough then eventually removing some
functionality may be considered if it is no longer worth maintaining.

### Does this Replace Berkshelf?

The Policyfile is definitely a replacement for the "environment
cookbook" pattern in Berkshelf. It also provides a dependency solver and
fetcher (thanks to some code from berks), so it may replace some other
berkshelf use cases. However it is much less opinionated than Berkshelf,
and may not replace Berkshelf for all use cases, so we'll have to see
how things turn out.

### Does this Force Me to Use the Single Cookbook per Repo Thing?

No. We're still figuring out the optimal way to support the "megarepo"
workflow, but it will be supported. In particular we have to study the
tradeoffs of versioning your Policyfile.rb files (we'll support other
names) with your chef-repo vs. outside of it. We plan to do some dogfood
testing to inform the design here.

Users who use the "megarepo" workflow may see some benefit to using
single repos for third-party cookbooks, but this will be optional and
users can convert from vendor branches piecemeal if they decide to do
so.

### Do I Have to Change My Workflow to Use This?

The answer to this depends on how you define "workflow." As noted above,
you can choose to have a chef-repo or not, and you can fetch third party
cookbooks using the Policyfile or an out of band mechanism (vendor
branches). You and your team can decide to publish only completely
integrated "release" cookbooks to the server if that works for you, but
you can also safely publish development versions of cookbooks to the
server without risk of mutating the production versions and without
needing a versioning scheme (devodd and friends) to workaround cookbook
mutability issues.

That said, the mechanics of how you get configuration code from your
workstation to production will be different. In particular, when using
the Policyfile feature in the recommended way, you cannot publish an
updated cookbook or role and have it applied immediately to all
machines. Tools that use the old APIs will need to be updated.

### Are Policyfiles Versioned?

There currently isn't any detailed design for the Chef Server policy API
(which will store the `Policyfile.lock.json` documents). One design
decision we have made is that the documents will be namespaced (by
`policy group`). This means that at minimum it will be possible to
independently update the policy for different stages of your release
process independently. For example, if you have policy groups for "dev,"
"stage," and "prod," you can iterate on new feature work in "dev" and
release a critical hot fix to "prod" independently of each other.

If this is all that's implemented, then you will be able to version your
policies by committing your `Policyfile.rb` and `Policyfile.lock.json`
documents to revision control and using a branching policy that fits
your release requirements. That said, features to support operations
such as reverting or undo and/or tracking changes over time will be
considered.

### What About Environments?

We have not made a final decision about how environments will work with
Policyfiles. In compatibility mode, you cannot use environments and
Policyfiles together, but this choice could be reversed. Policyfiles
**do** completely replace the cookbook version constraint portion of the
environments feature. However, environments do offer a useful way to set
environment-wide attributes, which some users rely on heavily. The main
sticking point is that environments provide the same double edged sword
as many other Chef features where updates to environments are propagated
immediately to all nodes in an environment. When done correctly, this is
very convenient, but it also allows mistakes to propagate to all nodes
immediately. Contrarily, if environment attributes are rolled into the
Policyfile, you can more easily test the effects of changes and control
the way these updates are applied, but it's more difficult to apply
changes globally.

## Compatibility Mode

The Policyfile feature depends on new APIs in Chef Server that don't yet
exist (these are listed in the "Known Limitation" sections below). In
order to provide a preview of the feature, the current implementation
operates in a compatibility mode that uses existing Chef Server APIs to
demonstrate the Policyfile behavior.

### Cookbook Artifact Storage

In compatibility mode, ChefDK must implement content-hash-based storage
of cookbooks using the existing `/cookbooks` endpoint. To do so, it maps
hash IDs to `X.Y.Z` version numbers. While this works to demonstrate the
Policyfile behavior, it is certainly a kludge. If you are trying the
Policyfile feature in compatibility mode, beware:

* Cookbooks uploaded by the policyfile commands will have very large
version numbers with no sort order. Any `chef-client` that is not
operating in policyfile mode will prefer these cookbooks to ones
uploaded normally unless you are dilligent about using environment
version constraints.
* The `/cookbooks` endpoint is not designed to be used this way, so it
doesn't show you the "real" version numbers or additional metadata about
these cookbooks. While we have plans to make arbitrary cookbook IDs
easier to manage in the final implementation, there's little we can do
about it in the exiting API.

### Policyfile Storage

In compatibility mode, ChefDK uses data bag items to store
`Policyfile.lock.json` documents. To minimize the chance of conflict
with other data bag items, ChefDK stores all of these documents in the
"policyfiles" data bag; individual `Policyfile.lock.json` revisions are
given IDs of the form `$policyname-policygroup`.

## Known Limitations

The implementation of the Policyfile feature is still **very**
incomplete. This is a (possibly not complete) list of planned features
and use cases that currently aren't implemented/supported.

### Conservative Updating

Individual cookbooks in a `Policyfile.lock.json` cannot be upgraded. You
have to recompute the entire thing from the `Policyfile.rb`. Support for
this will be added.

### Role Support

Roles currently cannot be used in the `Policyfile.rb` run list, but will
be supported in the future.

### Policyfile Attributes

The `Policyfile.rb` run_list will be able to have roles, which have
attributes. The `Policyfile.rb` will also allow setting attributes
directly. These will replace the role-level attributes in the precedence
hierarchy.

### Multiple Run List Support

This is intended to (at minimum) replace the functionality of override
run lists, which are not compatible with Policyfiles. The feature is
included in some design documentation, but not implemented.

### Private Cookbook Hosting

Currently you cannot host cookbooks behind your firewall. Eventually we
would like to provide two options for hosting cookbooks yourself:

* Upload cookbooks to a Chef Server or organization's `/cookbooks`
endpoint;
* Run your own copy of supermarket.

The first option requires implementation of a `/universe` endpoint on
the Chef Server, as described here: https://github.com/opscode/chef-rfc/blob/master/rfc014-universe-endpoint.md

The second option might be possible currently but has not been tested.
### Server API Support

In order to be completely usable in production, two new endpoints must
be added to the Chef Server:

* "cookbook artifact" endpoint: This would allow users to store and
retrieve cookbooks with arbitrary IDs. The compatibility mode
implementation works around this limitation by mapping arbitrary IDs to
version numbers, which is a kludge.
* Policyfile endpoint: This would store Policyfile.lock documents and
associate them with a policy group.


