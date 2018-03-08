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
require "chef-dk/generator"

describe ChefDK::Generator do

  before(:each) do
    ChefDK::Generator.reset
  end

  describe "self.add_attr_to_context" do
    it "adds an accessor for the symbol to the context object" do
      ChefDK::Generator.add_attr_to_context(:snakes)
      expect(ChefDK::Generator.context.snakes = 5).to be_eql(5)
      expect(ChefDK::Generator.context.snakes).to be_eql(5)
    end

    it "delegates the accessor from the template helper" do
      ChefDK::Generator.add_attr_to_context(:snakes)
      ChefDK::Generator.context.snakes = 5
      expect(ChefDK::Generator::TemplateHelper.instance_methods).to include(:snakes)
    end

    it "sets a value" do
      ChefDK::Generator.add_attr_to_context(:snakes, 5)
      expect(ChefDK::Generator.context.snakes).to be_eql(5)
    end
  end
end

class TmplTest
  include ChefDK::Generator::TemplateHelper
end

describe ChefDK::Generator::TemplateHelper do
  let(:license) { "all_rights" }
  let(:copyright_holder) { "Adam Jacob" }
  let(:helper) { TmplTest.new }

  before(:each) do
    ChefDK::Generator.reset
    ChefDK::Generator.add_attr_to_context(:license, license)
    ChefDK::Generator.add_attr_to_context(:copyright_holder, "Adam Jacob")
  end

  describe "license_description" do
    let(:license) { "all_rights" }
    context "all_rights" do
      it "should match the license" do
        expect(helper.license_description).to match(/^Copyright:: /)
      end

      it "should comment if requested" do
        expect(helper.license_description("#")).to match(/^# Copyright/)
      end
    end

    context "apachev2" do
      let(:license) { "apachev2" }
      it "should match the license" do
        expect(helper.license_description).to match(/Licensed under the Apache/)
      end

      it "should comment if requested" do
        expect(helper.license_description("#")).to match(/# Licensed under the Apache/)
      end
    end

    context "mit" do
      let(:license) { "mit" }
      it "should match the license" do
        expect(helper.license_description).to match(/Permission is hereby granted/)
      end

      it "should comment if requested" do
        expect(helper.license_description("#")).to match(/# Permission is hereby granted/)
      end
    end

    context "gplv2" do
      let(:license) { "gplv2" }
      it "should match the license" do
        expect(helper.license_description).to match(/This program is free software;/)
      end

      it "should comment if requested" do
        expect(helper.license_description("#")).to match(/# This program is free software;/)
      end
    end

    context "gplv3" do
      let(:license) { "gplv3" }
      it "should match the license" do
        expect(helper.license_description).to match(/This program is free software:/)
      end

      it "should comment if requested" do
        expect(helper.license_description("#")).to match(/# This program is free software:/)
      end
    end
  end

end
