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
require "shared/a_file_generator"
require "chef-dk/command/generator_commands/policyfile"

describe ChefDK::Command::GeneratorCommands::Policyfile do

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  subject(:generator) do
    generator = described_class.new(argv)
    allow(generator).to receive(:stdout).and_return(stdout_io)
    allow(generator).to receive(:stderr).and_return(stderr_io)
    generator
  end

  def generator_context
    ChefDK::Generator.context
  end

  before do
    allow(generator.chef_runner).to receive(:stdout).and_return(stdout_io)
    ChefDK::Generator.reset
    reset_tempdir
  end

  after(:each) do
    ChefDK::Generator::Context.reset
  end

  shared_examples_for "it creates a Policyfile" do

    it "configures the generator context" do
      Dir.chdir(tempdir) do
        generator.read_and_validate_params
        generator.setup_context

        expect(generator_context.policyfile_dir).to eq(tempdir)
        expect(generator_context.new_file_basename).to eq(new_file_basename)
      end
    end

    it "generates a Policyfile.rb in the CWD" do
      Dir.chdir(tempdir) do
        expect(generator.run).to eq(0)
        expect(File).to exist(File.join(tempdir, expected_file_name))
      end
    end

  end

  context "when ARGV is empty" do

    let(:argv) { [] }

    let(:expected_file_name) { "Policyfile.rb" }
    let(:new_file_basename) { "Policyfile" }

    include_examples "it creates a Policyfile"

  end

  context "when ARGV is a relative path with no `.rb' extension" do

    let(:argv) { ["MyPolicy"] }

    let(:expected_file_name) { "MyPolicy.rb" }
    let(:new_file_basename) { "MyPolicy" }

    include_examples "it creates a Policyfile"

  end

  context "when ARGV is a relative path with a `.rb' extension" do

    let(:argv) { ["MyApplication.rb"] }

    let(:expected_file_name) { "MyApplication.rb" }
    let(:new_file_basename) { "MyApplication" }

    include_examples "it creates a Policyfile"

  end

  context "when the current working directory is a chef repo" do

    let(:chef_repo_dot_txt) { File.join(tempdir, ".chef-repo.txt") }

    let(:policies_dir) { File.join(tempdir, "policyfiles") }

    let(:expected_policyfile_content) do
      <<~POLICYFILE_RB
        # Policyfile.rb - Describe how you want Chef to build your system.
        #
        # For more information on the Policyfile feature, visit
        # https://docs.chef.io/policyfile.html

        # A name that describes what the system you're building with Chef does.
        name 'my-app-frontend'

        # This lets you source cookbooks from your chef-repo.
        default_source :chef_repo, '../'

        # Where to find external cookbooks:
        default_source :supermarket

        # run_list: chef-client will run these recipes in the order specified.
        run_list 'my-app-frontend::default'

        # Specify a custom source for a single cookbook:
        # cookbook 'example_cookbook', path: '../cookbooks/example_cookbook'
      POLICYFILE_RB
    end

    before do
      FileUtils.touch(chef_repo_dot_txt)
      FileUtils.mkdir(policies_dir)
    end

    context "when ARGV is empty" do

      let(:argv) { [] }

      it "errors and explains a policy name is required when using a chef-repo" do
        Dir.chdir(tempdir) do
          expect(generator.run).to eq(1)
        end
        expect(File).to_not exist(File.join(tempdir, "Policyfile.rb"))
        expected_error = "ERROR: You must give a policy name when generating a policy in a chef-repo."
        expect(stderr).to include(expected_error)
      end

    end

    context "when ARGV is a single name with no path separators" do

      let(:argv) { ["my-app-frontend"] }

      let(:expected_policyfile_path) { File.join(policies_dir, "my-app-frontend.rb") }

      before do
        Dir.chdir(tempdir) do
          expect(generator.run).to eq(0)
        end
      end

      it "creates the policy under the policies/ directory" do
        expect(File).to exist(expected_policyfile_path)
      end

      it "adds chef_repo as a default source and uses argv for the policy name" do
        expect(IO.read(expected_policyfile_path)).to eq(expected_policyfile_content)
      end

    end

    context "when ARGV looks like a path" do

      let(:other_policy_dir) { File.join(tempdir, "other-policies") }

      let(:expected_policyfile_path) { File.join(other_policy_dir, "my-app-frontend.rb") }

      let(:argv) { [ "other-policies/my-app-frontend" ] }

      before do
        FileUtils.mkdir(other_policy_dir)

        Dir.chdir(tempdir) do
          expect(generator.run).to eq(0)
        end
      end

      it "creates the policy in the specified path" do
        expect(File).to exist(expected_policyfile_path)
      end

      it "adds chef_repo as a default source" do
        expect(IO.read(expected_policyfile_path)).to eq(expected_policyfile_content)
      end

    end

  end

  context "when ARGV has too many arguments" do

    let(:argv) { %w{ foo bar baz } }

    it "shows usage and exits" do
      expected_stdout = "Usage: chef generate policyfile [NAME] [options]"

      expect(generator.run).to eq(1)
      expect(stderr).to include(expected_stdout)
    end

  end

end
