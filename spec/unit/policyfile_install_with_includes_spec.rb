# -*- coding: UTF-8 -*-
#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "chef-dk/policyfile_lock.rb"

describe ChefDK::PolicyfileLock, "installing cookbooks from included policies" do

  context "when a policy is included from local disk" do

    it "maintains source locations for remote cookbooks (i.e., from github or supermarket)"

    it "maintains identifiers for remote cookbooks"

    context "and the included policy sources cookbooks from local disk" do
      # For example, imagine a directory layout like:
      #
      #    policies/
      #      - policy_that_includes_shared_policy_a.rb
      #      - shared_policy_folder/
      #        - shared_policy_a.rb
      #        - shared_policy_a.lock.json
      #        - shared_policy_b.rb
      #        - shared_policy_b.lock.json
      #    cookbooks/
      #      - webserver_cookbook/
      #        <etc.>
      #
      # In `policies/shared_policy_folder/shared_policy_a.rb`, a cookbook may be
      # sourced from local path with code like:
      #
      #     cookbook "webserver_cookbook", path: "../../cookbooks/webserver_cookbook"
      #
      # In the lockfile
      # `policies/shared_policy_folder/shared_policy_a.lock.json`, we'd have some
      # data like:
      #
      #     "cookbook_locks": {
      #       "webserver_cookbook": {
      #         "version": "0.1.0",
      #         "identifier": "ea96c99da079db9ff3cb22601638fabd5df49599",
      #         "source": "../../cookbooks/webserver_cookbook",
      #
      # However, when we want to `chef install` cookbooks for
      # `policy_that_includes_shared_policy_a.rb`, we are one directory higher
      # and the path needs to be adjusted to `../cookbooks/webserver_cookbook` (only one set of `..`s)
      it "adjusts relative paths for local path cookbooks"

      # counter-example to above, if the filesystem path is absolute, leave it as-is
      it "does not adjust non-relative paths for local path cookbooks"

      context "and the local path cookbook content is unchanged" do

        it "does not raise an error when installing"

      end

      context "and the local path cookbook is modified so the identifier doesn't match" do

        it "raises an error when installing"

        it "suggests that the error may be resolved by updating the included policy"

      end

      context "and the local path cookbook does not exist" do

        it "raises an error when installing"

        it "includes the name and source location of the included policy"

      end

    end
  end

  context "when a policy is included from a Chef Server" do

    it "maintains source locations for remote cookbooks (i.e., from github or supermarket)"

    it "maintains identifiers for remote cookbooks"

    context "and the included policy sources cookbooks from local disk" do

      # NOTE: this will need to be a new kind of source in CookbookOmnifetch.
      # We have support for "regular" cookbooks in Chef Server, but for this
      # case we need to get the actual cookbook artifact at the specified revision_id
      it "adjusts the source location for the cookbook to the Chef Server's cookbook artifact store"

      it "maintains the identifier for the cookbooks"

      context "and the cookbook_artifact has been removed from the chef server" do

        # If the user is correctly using `chef clean-policy-revisions` and
        # `chef clean-policy-cookbooks`, this case shouldn't occur, but should
        # still have a clean and informative error
        it "raises an error explaining that the included policy depends on a cookbook artifact that has been deleted"

      end

    end
  end

  context "when a policy is included from a remote git repo" do

    context "and the included policy sources cookbooks from local disk" do

      # ¯\_(ツ)_/¯
      it "raises an error explaining that local path cookbooks cannot be used in policies included from git repos"

    end
  end
end
