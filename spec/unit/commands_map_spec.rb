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
require "chef-dk/commands_map"
require "stringio"

describe ChefDK::CommandsMap do

  subject(:mapping) { ChefDK::CommandsMap.new }

  before do
    mapping.builtin("example", :Example)
    mapping.builtin("hypenated-example", :HyphenatedExample)
    mapping.builtin("explicit-path-example", :ExplicitPathExample, require_path: "unit/fixtures/command/explicit_path_example")
    mapping.builtin("documented-example", :DocumentedExample, desc: "I have documentation")
  end

  it "defines a subcommand mapping" do
    expect(mapping.have_command?("example")).to be true
  end

  it "infers a non-hypenated command's require path" do
    expect(mapping.spec_for("example").require_path).to eq("chef-dk/command/example")
  end

  it "infers a hyphenated command's require path" do
    expect(mapping.spec_for("hypenated-example").require_path).to eq("chef-dk/command/hypenated_example")
  end

  it "lists the available commands" do
    expect(mapping.command_names).to match_array(%w{example hypenated-example explicit-path-example documented-example})
  end

  it "keeps the docstring of a command" do
    expect(mapping.spec_for("documented-example").description).to eq("I have documentation")
  end

  it "creates an instance of a command" do
    expect(mapping.instantiate("explicit-path-example")).to be_an_instance_of(ChefDK::Command::ExplicitPathExample)
  end

end
