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

require 'spec_helper'
require 'chef-dk/command/generator_commands/cookbook'

describe ChefDK::Command::GeneratorCommands::Cookbook do

  let(:argv) { %w[new_cookbook] }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w[
      .gitignore
      .kitchen.yml
      Berksfile
      chefignore
      metadata.rb
      README.md
      recipes
      recipes/default.rb
    ]
  end

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "new_cookbook", relpath)
    end
  end

  subject(:cookbook_generator) do
    g = described_class.new(argv)
    allow(g).to receive(:cookbook_path_in_git_repo?).and_return(false)
    g
  end

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
  end

  it "configures the chef runner" do
    expect(cookbook_generator.chef_runner).to be_a(ChefDK::ChefRunner)
    expect(cookbook_generator.chef_runner.cookbook_path).to eq(File.expand_path('lib/chef-dk/skeletons', project_root))
  end

  context "when given invalid/incomplete arguments" do

    let(:expected_help_message) do
      "Usage: chef generate cookbook NAME [options]\n"
    end


    def with_argv(argv)
      generator = described_class.new(argv)
      allow(generator).to receive(:stdout).and_return(stdout_io)
      allow(generator).to receive(:stderr).and_return(stderr_io)
      generator
    end

    it "prints usage when args are empty" do
      with_argv([]).run
      expect(stdout_io.string).to eq(expected_help_message)
    end

  end

  context "when given the name of the cookbook to generate" do

    let(:argv) { %w[new_cookbook] }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(Dir.pwd)
      expect(generator_context.cookbook_name).to eq("new_cookbook")
    end

    it "creates a new cookbook" do
      Dir.chdir(tempdir) do
        allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        cookbook_generator.run
      end
      generated_files = Dir.glob("#{tempdir}/new_cookbook/**/*", File::FNM_DOTMATCH)
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
      let(:file) { File.join(tempdir, "new_cookbook", "README.md") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# new_cookbook" }
      end
    end

    describe ".kitchen.yml" do
      let(:file) { File.join(tempdir, "new_cookbook", ".kitchen.yml") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { /\s*- recipe\[new_cookbook::default\]/ }
      end
    end

    describe "metadata.rb" do
      let(:file) { File.join(tempdir, "new_cookbook", "metadata.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { /name\s+'new_cookbook'/ }
      end
    end

    describe "recipes/default.rb" do
      let(:file) { File.join(tempdir, "new_cookbook", "recipes", "default.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# Cookbook Name:: new_cookbook" }
      end
    end

  end

  context "when given the path to the cookbook to generate" do
    let(:argv) { [ File.join(tempdir, "a_new_cookbook") ] }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(tempdir)
      expect(generator_context.cookbook_name).to eq("a_new_cookbook")
    end

  end

  context "when given a generator-cookbook path" do

    let(:default_generator_cookbook_path) { File.expand_path('lib/chef-dk/skeletons/code_generator', project_root) }

    let(:generator_cookbook_path) { File.join(tempdir, 'a_generator_cookbook') }
    let(:argv) { ["new_cookbook", "--generator-cookbook", generator_cookbook_path] }

    before do
      reset_tempdir

      cookbook_generator.read_and_validate_params
    end

    it "configures the generator context" do
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(Dir.pwd)
      expect(generator_context.cookbook_name).to eq("new_cookbook")
      expect(cookbook_generator.chef_runner.cookbook_path).to eq(tempdir)
      expect(cookbook_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::cookbook]"])
    end

    context "with an invalid generator-cookbook path" do

      it "fails to create the cookbook cookbook" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          # TODO: improve messaging for this error
          expect { cookbook_generator.run }.to raise_error(Chef::Exceptions::CookbookNotFound)
        end
      end

    end

    context "with a generator-cookbook path to a specific cookbook" do

      let(:metadata_file) { File.join(generator_cookbook_path, "metadata.rb") }

      before do
        FileUtils.cp_r(default_generator_cookbook_path, generator_cookbook_path)

        # have to update metadata with the correct name
        IO.binwrite(metadata_file, "name 'a_generator_cookbook'")
      end

      it "creates the cookbook" do
        expect(cookbook_generator.chef_runner.cookbook_path).to eq(tempdir)
        expect(cookbook_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::cookbook]"])

        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          cookbook_generator.run
        end
      end

    end

    context "with a generator-cookbook path to a directory containing a 'code_generator' cookbook" do

      before do
        FileUtils.mkdir_p(generator_cookbook_path)
        FileUtils.cp_r(default_generator_cookbook_path, generator_cookbook_path)

        allow(cookbook_generator).to receive(:stderr).and_return(stderr_io)
      end

      it "creates a new cookbook (and warns about deprecated usage)" do
        allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)

        Dir.chdir(tempdir) do
          cookbook_generator.run
        end
        generated_files = Dir.glob("#{tempdir}/new_cookbook/**/*", File::FNM_DOTMATCH)
        expected_cookbook_files.each do |expected_file|
          expect(generated_files).to include(expected_file)
        end

        code_generator_path = File.join(generator_cookbook_path, "code_generator")
        warning_message = "WARN: Please configure the generator cookbook by giving the full path to the desired cookbook (like '#{code_generator_path}')"

        expect(stderr_io.string).to include(warning_message)
      end
    end
  end

  context "when given generic arguments to populate the generator context" do
    let(:argv) { [ "new_cookbook", "--generator-arg", "key1=value1", "-a", "key2=value2", "-a", " key3 = value3 " ] }

    before do
      reset_tempdir
    end

    it "configures the generator context for long form option key1" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key1).to eq('value1')
    end

    it "configures the generator context for short form option key2" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key2).to eq('value2')
    end

    it "configures the generator context for key3 containing additional spaces" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key3).to eq('value3')
    end

  end

end
