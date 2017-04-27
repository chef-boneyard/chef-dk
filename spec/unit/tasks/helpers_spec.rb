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
require_relative "../../../tasks/helpers"

class RakeMock

end

describe "Rake 'dependencies' task" do
  let(:rake_mock) { Class.new { include RakeDependenciesTaskHelpers }.new }
  let(:product_name) { "chef" }
  let(:gemfile_name) { "chef" }
  let(:gemfile) { 'gem "chef", github: "chef/chef", branch: "0.0.0"' }
  let(:expected_version) { "0.0.1" }

  before do
    allow(rake_mock).to receive(:puts)
    allow(rake_mock).to receive(:get_latest_version_for).with(product_name).and_return(expected_version)
  end

  describe "update_gemfile_from_stable" do
    context "when gemfile does not contain the expected string" do
      let(:gemfile) { "These are not the droids you are looking for." }

      it "raises an error" do
        expect { rake_mock.update_gemfile_from_stable(gemfile, product_name, gemfile_name) }.to raise_error(/Gemfile does not have a line of the form/)
      end
    end

    context "when gemfile does contain the expected string" do
      let(:prefix) { "" }
      let(:expected_output) { "gem \"chef\", github: \"chef/chef\", branch: \"#{prefix}#{expected_version}\"" }

      context "and the version string does not have a prefix" do
        it "updates the gemfile entry to the newer version" do
          expect(rake_mock.update_gemfile_from_stable(gemfile, product_name, gemfile_name))
            .to eq(expected_output)
        end
      end

      context "and the version is the same" do
        let(:expected_version) { "0.0.0" }
        it "warns the user that the version is not being updated" do
          expect(rake_mock).to receive(:puts).with(/version in Gemfile already at latest stable/)
          expect(rake_mock.update_gemfile_from_stable(gemfile, product_name, gemfile_name))
            .to eq(expected_output)
        end
      end

      context "and a prefix is specified" do
        let(:prefix) { "v" }
        it "updates the gemfile entry to the newer version" do
          expect(rake_mock.update_gemfile_from_stable(gemfile, product_name, gemfile_name, prefix))
            .to eq(expected_output)
        end
      end
    end
  end
end
