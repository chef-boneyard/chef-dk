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
require "chef-dk/shell_out"

describe ChefDK::ShellOut do

  describe "providing the API expected by CookbookOmnifetch" do

    it "provides a `shell_out` class method" do
      expect(described_class).to respond_to(:shell_out)
    end

    it "responds to #success?" do
      expect(described_class.new("echo 'foo'")).to respond_to(:success?)
    end

  end
end
