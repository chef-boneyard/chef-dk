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
require "chef-dk/policyfile/reports/upload"

# For the LockedCookbookForUpload class:
require "chef-dk/policyfile/uploader"

# Used for verifying doubles
require "chef-dk/policyfile/cookbook_locks"

describe ChefDK::Policyfile::Reports::Upload do

  let(:ui) { TestHelpers::TestUI.new }

  let(:reused_cookbooks) { [] }

  let(:uploaded_cookbooks) { [] }

  subject(:upload_report) { described_class.new(ui: ui, reused_cbs: reused_cookbooks, uploaded_cbs: uploaded_cookbooks) }

  it "has a ui object" do
    expect(upload_report.ui).to eq(ui)
  end

  it "has a list of cookbooks that are being uploaded" do
    expect(upload_report.uploaded_cbs).to equal(uploaded_cookbooks)
  end

  it "has a list of cookbooks that would be uploaded but are already on the server" do
    expect(upload_report.reused_cbs).to equal(reused_cookbooks)
  end

  describe "reporting uploaded and reused cookbooks" do

    def cb_with_lock(name, version, identifier)
      lock = instance_double("ChefDK::Policyfile::CookbookLock",
                             name: name,
                             version: version,
                             identifier: identifier)

      ChefDK::Policyfile::Uploader::LockedCookbookForUpload.new(nil, lock)
    end

    let(:cookbook_one) do
      cb_with_lock("short-name", "10.11.12", "49582c3db4e3b54674ecfb57fe82157720350274")
    end

    let(:cookbook_two) do
      cb_with_lock("a-longer-named-cookbook", "1.0.0", "e4ac353bebdc949cd2cd8ce69983a56b96917dfa")
    end

    let(:reused_cookbooks) { [ cookbook_one, cookbook_two ] }

    let(:cookbook_three) do
      cb_with_lock("foo", "1.2.42", "cb61daebfb0d255cae928ca1a92db29b055755cf")
    end

    let(:cookbook_four) do
      cb_with_lock("barbazqux", "12.34.5678", "1241ea6f9866d0e61d11129bb32e5fc96cd2bac0")
    end

    let(:uploaded_cookbooks) { [ cookbook_three, cookbook_four ] }

    it "prints a table showing the re-used and uploaded cookbooks" do
      upload_report.show

      expected_output = <<~E
        Using    short-name              10.11.12   (49582c3d)
        Using    a-longer-named-cookbook 1.0.0      (e4ac353b)
        Uploaded foo                     1.2.42     (cb61daeb)
        Uploaded barbazqux               12.34.5678 (1241ea6f)
      E
      expect(ui.output).to eq(expected_output)
    end

  end

end
