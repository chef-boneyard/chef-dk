#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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

require 'spec_helper'

describe "building and solving a dependency graph" do

  describe "Build a graph from a policyfile" do

    context "Given no local or git cookbooks and an empty run list" do
      it "emits an empty solution"
    end

    context "Given a run list and no local or git cookbooks" do
      context "And the default source is the community site" do
        it "emits a solution with cookbooks from the community site"
      end

      context "And the default source is the chef-server" do
        it "emits a solution with cookbooks from the chef-server"
      end
    end

    context "Given a local cookbook with no dependencies and only that cookbook in the run list" do
      it "emits a solution with just the one cookbook"
    end

    context "Given a local cookbook with a dependency and only the local cookbook in the run list" do
      context "And the default source is the community site" do
        # TODO: break into smaller assertions
        it "emits a solution with the cookbook, its dependency and transitive dependencies as given by the community metadata API service."
      end
      context "And the default source is the chef server" do
        it "emits a solution with the cookbook, its dependency and transitive dependencies as given by the chef-server"
      end
    end

    context "Given a git-sourced cookbook with no dependencies and only the git cookbook in the run list" do
      it "emits a solution with just the one cookbook."
    end

    context "Given a git-sourced cookbook with a dependency and only the git cookbook in the run list" do
      context "And the default source is the community site" do
        # TODO: break into smaller assertions
        it "emits a solution with the cookbook, its dependency and transitive dependencies as given by the community metadata API service."
      end
      context "And the default source is the chef server" do
        # TODO: break into smaller assertions
        it "emits a solution with the cookbook, its dependency and transitive dependencies as given by the chef-server"
      end
    end

    context "Given a local cookbook with a run list containing the local cookbook and another cookbook" do
      context "And the default source is the community site" do
        it "emits a solution with the local cookbook and a remote cookbook that satisfies the run list requirements, plus dependency and transitive dependencies as given by the community metadata API service."
      end
      context "And the default source is the chef server" do
        it "emits a solution with the local cookbook and a remote cookbook that satisfies the run list requirements, plus dependency and transitive dependencies as given by the chef server."
      end
    end

    context "Given a local cookbook with a dependency and another local cookbook that satisfies the dependency" do
      it "emits a solution using the local cookbooks"
    end

    context "Given a local cookbook with a dependency and a git cookbook that satisfies the dependency" do
      it "emits a solution with the git and local cookbooks"
    end

    context "Given two local cookbooks with conflicting dependencies" do
      it "raises an error explaining that no solution was found."
    end

    context "Given a local cookbook with dependencies with conflicting transitive dependencies" do
      it "raises an error explaining that no solution was found."
    end

  end
end
