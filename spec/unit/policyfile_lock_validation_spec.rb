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
#require 'shared/setup_git_cookbooks'
#require 'shared/fixture_cookbook_checksums'
#require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile_lock.rb'

describe ChefDK::PolicyfileLock, "validating locked cookbooks" do

  context "when no cookbooks have changed" do

    it "validation succeeds"

  end

  context "when a :path sourced cookbook is missing" do

    it "reports the missing cookbook and fails validation"

  end

  context "when a cached cookbook is missing" do

    it "reports the missing cookbook and fails validation"

  end

  context "when a :path sourced cookbook has updated content" do

    it "updates the lockfile with the new checksum and validation succeeds"

  end

  context "when a :path source cookbook has added a dependency satisfied by the current cookbook set" do

    it "updates the lockfile with the new checksum and validation succeeds"

  end

  context "when a :path source cookbook has added a dependency not satisfied by the current cookbook set" do

    it "reports the not-satisfied dependency and validation fails"

  end

  context "when a :path source cookbook has modified a dep constraint and the new constraint is satisfied" do

    it "updates the lockfile with the new checksum and validation succeeds"

  end

  context "when a :path source cookbook has modified a dep constraint and the new constraint is not satisfied" do

    it "reports the not-satisfied dependency and validation fails"

  end

  context "when a cached cookbook is modified" do

    # This basically means the user modified the cached cookbook. There's no
    # technical reason we need to be whiny about this, but if we treat it like
    # we would a path cookbook, you could end up with two cookbooks that look
    # like the canonical (e.g.) apache2 1.2.3 cookbook from supermarket with no
    # indication of which is which.
    #
    # We'll treat it like an error, but we need to provide a "pristine"
    # function to let the user recover.
    it "reports the modified cached cookbook and validation fails"
  end
end

