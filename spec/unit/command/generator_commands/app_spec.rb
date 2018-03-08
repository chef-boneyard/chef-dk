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
require "shared/custom_generator_cookbook"
require "chef-dk/command/generator_commands/app"

describe ChefDK::Command::GeneratorCommands::App do

  let(:argv) { %w{new_app} }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w{
      .gitignore
      .kitchen.yml
      test
      test/integration
      test/integration/default
      test/integration/default/default_test.rb
      README.md
      cookbooks/new_app/Berksfile
      cookbooks/new_app/chefignore
      cookbooks/new_app/metadata.rb
      cookbooks/new_app/recipes
      cookbooks/new_app/recipes/default.rb
      cookbooks/new_app/spec
      cookbooks/new_app/spec/spec_helper.rb
      cookbooks/new_app/spec/unit
      cookbooks/new_app/spec/unit/recipes
      cookbooks/new_app/spec/unit/recipes/default_spec.rb
    }
  end

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "new_app", relpath)
    end
  end

  subject(:cookbook_generator) { described_class.new(argv) }

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
  end

  include_examples "custom generator cookbook" do

    let(:generator_arg) { "new_app" }

    let(:generator_name) { "app" }

  end

  context "when given the name of the cookbook to generate" do

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.app_root).to eq(Dir.pwd)
      expect(generator_context.app_name).to eq("new_app")
      expect(generator_context.cookbook_root).to eq(File.join(Dir.pwd, "new_app", "cookbooks"))
      expect(generator_context.cookbook_name).to eq("new_app")
      expect(generator_context.recipe_name).to eq("default")
    end

    describe "generated files" do
      it "creates a new cookbook" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          cookbook_generator.run
        end
        generated_files = Dir.glob(File.join(tempdir, "new_app", "**", "*"), File::FNM_DOTMATCH)
        expected_cookbook_files.each do |expected_file|
          expect(generated_files).to include(expected_file)
        end
      end

      shared_examples_for "a generated file" do |context_var|
        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            cookbook_generator.run
          end
        end

        it "should contain #{context_var} from the generator context" do
          expect(File.read(file)).to match line
        end
      end

      describe "README.md" do
        let(:file) { File.join(tempdir, "new_app", "README.md") }

        include_examples "a generated file", :cookbook_name do
          let(:line) { "# new_app" }
        end
      end

      describe ".kitchen.yml" do
        let(:file) { File.join(tempdir, "new_app", ".kitchen.yml") }

        include_examples "a generated file", :cookbook_name do
          let(:line) { /\s*- recipe\[new_app::default\]/ }
        end
      end

      describe "test/integration/default/default_test.rb" do
        let(:file) { File.join(tempdir, "new_app", "test", "integration", "default", "default_test.rb") }

        include_examples "a generated file", :cookbook_name do
          let(:line) { "describe port" }
        end
      end

      describe "cookbooks/new_app/metadata.rb" do
        let(:file) { File.join(tempdir, "new_app", "cookbooks", "new_app", "metadata.rb") }

        include_examples "a generated file", :cookbook_name do
          let(:line) { /name\s+'new_app'/ }
        end
      end

      describe "cookbooks/new_app/recipes/default.rb" do
        let(:file) { File.join(tempdir, "new_app", "cookbooks", "new_app", "recipes", "default.rb") }

        include_examples "a generated file", :cookbook_name do
          let(:line) { "# Cookbook:: new_app" }
        end
      end

      describe "cookbooks/new_app/spec/unit/recipes/default_spec.rb" do
        let(:file) { File.join(tempdir, "new_app", "cookbooks", "new_app", "spec", "unit", "recipes", "default_spec.rb") }

        include_examples "a generated file", :cookbook_name do
          let(:line) { "describe \'new_app::default\' do" }
        end
      end

    end
  end
end
