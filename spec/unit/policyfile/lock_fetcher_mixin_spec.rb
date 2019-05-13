#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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
require "chef-dk/policyfile/lock_fetcher_mixin"

describe ChefDK::Policyfile::LockFetcherMixin do
  include ChefDK::Policyfile::LockFetcherMixin

  context "validate_revision_id" do
    let(:included_id) { "6d707130ea67bf5e475ddb40b1de7b799a15a665187b12b0c3e41a517d0fc5fd" }

    context "when included_id is valid" do
      let(:source_options) { { policy_revision_id: included_id } }

      it "returns nil" do
        expect(validate_revision_id(included_id, source_options)).to eq(nil)
      end
    end

    context "when included_id is a valid short revision id" do
      let(:source_options) { { policy_revision_id: "6d707130ea" } }

      it "returns nil" do
        expect(validate_revision_id(included_id, source_options)).to eq(nil)
      end
    end

    context "when source data does not include revision id" do
      let(:source_options) { {} }

      it "returns nil" do
        expect(validate_revision_id(included_id, source_options)).to eq(nil)
      end
    end

    context "when source data includes an invalid revision id" do
      let(:invalid_id) { "invalid_id" }
      let(:source_options) { { policy_revision_id: invalid_id } }

      it "raises ChefDK::InvalidLockfile" do
        expect { validate_revision_id(included_id, source_options) }.to raise_error(ChefDK::InvalidLockfile, /Expected policy_revision_id/)
      end
    end
  end
end
