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
require "chef-dk/policyfile/lock_applier"
require "chef-dk/policyfile_compiler"
require "chef-dk/policyfile_lock"

describe ChefDK::Policyfile::LockApplier do
  let(:lock) { instance_double("ChefDK::Policyfile::PolicyfileLock") }
  let(:compiler) { instance_double("ChefDK::Policyfile::PolicyfileCompiler") }
  let(:lock_applier) { ChefDK::Policyfile::LockApplier.new(lock, compiler) }

  let(:included_policy_1) do
    instance_double("ChefDK::Policyfile::PolicyfileLocationSpec",
                    name: "policy1")
  end

  let(:included_policy_2) do
    instance_double("ChefDK::Policyfile::PolicyfileLocationSpec",
                    name: "policy2")
  end

  let(:included_policy_lock_1) do
    {
      "name" => "policy1",
      "source_options" => {
        "some_name" => "policy1_name",
      },
    }
  end

  let(:included_policy_lock_2) do
    {
      "name" => "policy2",
      "source_options" => {
        "some_name" => "policy2_name",
      },
    }
  end

  let(:lock_location_specs) { [] }
  let(:included_policy_locks) { [] }

  before do
    allow(compiler).to receive(:included_policies).and_return(lock_location_specs)
    allow(lock).to receive(:included_policy_locks).and_return(included_policy_locks)
  end

  context "when no included policies are unlocked" do
    let(:lock_location_specs) { [included_policy_1, included_policy_2] }
    let(:included_policy_locks) { [included_policy_lock_1, included_policy_lock_2] }

    it "provides the locked source options for all policies" do
      expect(included_policy_1).to receive(:apply_locked_source_options).with(included_policy_lock_1["source_options"])
      expect(included_policy_2).to receive(:apply_locked_source_options).with(included_policy_lock_2["source_options"])
      lock_applier.apply!
    end
  end

  context "when a included policy is unlocked" do
    let(:lock_location_specs) { [included_policy_1, included_policy_2] }
    let(:included_policy_locks) { [included_policy_lock_1, included_policy_lock_2] }

    it "does not provide the locked source options for that policy" do
      expect(included_policy_1).not_to receive(:apply_locked_source_options)
      expect(included_policy_2).to receive(:apply_locked_source_options).with(included_policy_lock_2["source_options"])
      lock_applier
        .with_unlocked_policies(["policy1"])
        .apply!
    end
  end

  context "when all included policies are unlocked" do
    let(:lock_location_specs) { [included_policy_1, included_policy_2] }
    let(:included_policy_locks) { [included_policy_lock_1, included_policy_lock_2] }

    it "does not provide locked source options for any policies" do
      expect(included_policy_1).not_to receive(:apply_locked_source_options)
      expect(included_policy_2).not_to receive(:apply_locked_source_options).with(included_policy_lock_2["source_options"])
      lock_applier
        .with_unlocked_policies(:all)
        .apply!
    end
  end
end
