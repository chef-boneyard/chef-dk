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

require "chef-dk/policyfile/null_cookbook_source"

describe ChefDK::Policyfile::NullCookbookSource do

  let(:cookbook_source) { ChefDK::Policyfile::NullCookbookSource.new }

  it "emits an empty graph" do
    expect(cookbook_source.universe_graph).to eq({})
  end

  it "emits a not supported error when attempting to get source options for a cookbook" do
    expect { cookbook_source.source_options_for("foo", "1.2.3") }.to raise_error(ChefDK::UnsupportedFeature)
  end

end
