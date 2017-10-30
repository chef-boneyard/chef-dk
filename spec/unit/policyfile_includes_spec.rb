# -*- coding: UTF-8 -*-
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

require "spec_helper"
require "chef-dk/policyfile_compiler"

describe ChefDK::PolicyfileCompiler, "including upstream policy locks" do

  context "when no policies are included" do

    # TODO: an empty array here is probably fine?
    it "does not emit included policies information in the lockfile"

  end

  context "when one policy is included" do

    it "emits a lockfile describing the source of the included policy"

    # currently you must have a run list in a policyfile, but it should now
    # become possible to make a combo-policy just by combining other policies
    context "when the including policy does not have a run list" do

      it "emits a lockfile with an identical run list as the included policy"

    end

    context "when the including policy has a run list" do

      it "appends run list items from the including policy to the included policy's run list, removing duplicates"

    end

    context "when the policies have named run lists" do

      context "and no named run lists are shared between the including and included policy" do

        it "preserves the named run lists as given in both policies"

      end

      context "and some named run lists are shared between the including and included policy" do

        it "appends run lists items from the including policy's run lists to the included policy's run lists, removing duplicates"

      end

    end

    context "when no cookbooks are shared as dependencies or transitive dependencies" do

      it "does not raise a have conflicting dependency requirements error"

      it "emits a lockfile where cookbooks pulled from the upstream are at identical versions"

      it "solves the dependencies added by the top-level policyfile and emits them in the lockfile"

    end

    context "when some cookbooks are shared as dependencies or transitive dependencies" do

      context "and the including policy's dependencies can be solved with the included policy's locks" do

        it "solves the dependencies added by the top-level policyfile and emits them in the lockfile"

      end

      context "and the including policy's dependencies cannot be solved with the included policy's locks" do

        it "raises an error describing the conflict"

        it "includes the name and location of the included policy in the error message"

        it "includes the source of the conflicting dependency constraint from the including policy"

      end

    end

    context "when the included policy does not have attributes that conflict with the including policy" do

      it "emits a lockfile with the attributes from both merged"

    end

    context "when the included policy has attributes that conflict with the including policy's attributes" do

      it "raises an error describing all attribute conflicts"

      it "includes the name and location of the included policy in the error message"

      it "includes the source location of the conflicting attribute in the including policy"

    end

  end

  context "when several policies are included" do

    context "when no cookbooks are shared as dependencies or transitive dependencies by included policies" do

      it "does not raise a have conflicting dependency requirements error"

      it "emits a lockfile where cookbooks pulled from the upstreams are at identical versions"

      it "solves the dependencies added by the top-level policyfile"

    end

    context "when some cookbooks appear as dependencies or transitive dependencies of some included policies" do

      context "and the locked versions of the cookbooks match" do

        it "solves the dependencies with the matching versions"

      end

      context "and the locked versions of the cookbooks do not match" do

        it "raises an error describing the conflict"

        it "includes the name and location of the conflicting included policies in the error message"

      end

    end

    context "when the included policies do not have conflicting attributes" do

      it "emits a lockfile with the included policies' attributes merged"

    end

    context "when the included policies have conflicting attributes" do

      it "raises an error describing the conflict"

      it "includes the name an location of the conflicting included policies in the error message"

    end

  end

end


