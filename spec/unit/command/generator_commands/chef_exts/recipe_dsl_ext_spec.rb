#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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
require "stringio"

require "chef/config"
require "chef/recipe"
require "chef/run_context"
require "chef/event_dispatch/dispatcher"
require "chef/policy_builder"
require "chef/formatters/doc"
require "chef/cookbook/file_vendor"
require "chef/cookbook/file_system_file_vendor"
require "chef/cookbook/cookbook_collection"
require "chef/cookbook_loader"

require "ohai/system"

require "chef-dk/command/generator_commands/chef_exts/recipe_dsl_ext"
require "chef-dk/command/generator_commands/chef_exts/quieter_doc_formatter"

describe ChefDK::RecipeDSLExt do

  before(:all) { Chef.reset! }

  let(:stdout) { StringIO.new }

  let(:stderr) { StringIO.new }

  let(:doc_formatter) do
    Chef::Formatters.new(:chefdk_doc, stdout, stderr)
  end

  let(:event_dispatcher) do
    Chef::EventDispatch::Dispatcher.new.tap do |d|
      d.register(doc_formatter)
    end
  end

  let(:run_list) { [ ] }

  let(:ohai) do
    Ohai::System.new.tap do |o|
      o.all_plugins(%w{platform platform_version})
    end
  end

  let(:policy_builder) do
    Chef::PolicyBuilder::Dynamic.new("chef-dk", ohai.data, {}, nil, event_dispatcher).tap do |b|
      b.load_node
      b.build_node
      b.node.run_list(*run_list)
      b.expand_run_list
    end
  end

  # In some circumstances (not totally clear about what), compat resource gets
  # loaded and it does some weird stuff to `Chef::Recipe.new` which can fail if
  # you pass in a cookbook name that is bogus and not-falsey. Using `nil` for
  # the cookbook name works around that.
  # https://github.com/chef-cookbooks/compat_resource/blob/3d948a5a9cabccddc7cf5e48dfea796a6b557a44/files/lib/chef_compat/monkeypatches/chef/recipe.rb#L8-L15
  let(:cookbook_name) { nil }

  let(:recipe_name) { "example" }

  let(:run_context) { policy_builder.setup_run_context }

  let(:recipe) { Chef::Recipe.new(cookbook_name, recipe_name, run_context) }

  before do
    Chef::Config.solo_legacy_mode = true
    Chef::Config.color = true
    Chef::Config.diff_disabled = true
    Chef::Config.use_policyfile = false
  end

  describe "silence_chef_formatter" do

    before do
      recipe.silence_chef_formatter
    end

    let(:formatter) { run_context.events.subscribers.first }

    it "replaces the default formatter with a null formatter" do
      expect(formatter).to be_a(Chef::Formatters::NullFormatter)
    end

    it "passes stdout and stderr from the default formatter to the new one" do
      expect(formatter.output.out).to be(stdout)
      expect(formatter.output.err).to be(stderr)
    end

  end

end
