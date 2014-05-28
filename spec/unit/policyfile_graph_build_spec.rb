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

describe "Build a graph from a policyfile" do

  # Given no local or git cookbooks and an empty run list
  # * it emits an empty solution

  # Given a run list and no local or git cookbooks
  #   And the default source is the community site
  #   * it emits a solution with cookbooks from the community site
  #   And the default source is the chef-server
  #   * it emits a solution with cookbooks from the chef-server

  # Given a local cookbook with no dependencies and only that cookbook in the run list:
  # * it emits a solution with just the one cookbook

  # Given a local cookbook with a dependency and only the local cookbook in the run list:
  #   And the default source is the community site:
  #   * it emits a solution with the cookbook, its dependency and transitive
  #     dependencies as given by the community metadata API service.
  #   And the default source is the chef server:
  #   * it emits a solution with the cookbook, its dependency and transitive
  #     dependencies as given by the chef-server

  # Give a git-sourced cookbook with no dependencies and only the git cookbook in the run list:
  # * it emits a solution with just the one cookbook.

  # Given a git-sourced cookbook with a dependency and only the git cookbook in the run list:
  #   And the default source is the community site:
  #   * it emits a solution with the cookbook, its dependency and transitive
  #     dependencies as given by the community metadata API service.
  #   And the default source is the chef server:
  #   * it emits a solution with the cookbook, its dependency and transitive
  #     dependencies as given by the chef-server

  # Given a local cookbook with a run list containing the local cookbook and another cookbook:
  #   And the default source is the community site:
  #   * it emits a solution with the local cookbook and a remote cookbook that
  #   satisfies the run list requirements, plus dependency and transitive
  #   dependencies as given by the community metadata API service.
  #   And the default source is the chef server:
  #   * it emits a solution with the local cookbook and a remote cookbook that
  #   satisfies the run list requirements, plus dependency and transitive
  #   dependencies as given by the chef server.

  # Given a local cookbook with a dependency and another local cookbook that satisfies the dependency:
  # * it emits a solution using the local cookbooks

  # Given a local cookbook with a dependency and a git cookbook that satisfies the dependency:
  # * it emits a solution with the git and local cookbooks

  # Given two local cookbooks with conflicting dependencies
  # * it raises an error explaining that no solution was found.

  # Given a local cookbook with dependencies with conflicting transitive dependencies
  # * it raises an error explaining that no solution was found.

end
