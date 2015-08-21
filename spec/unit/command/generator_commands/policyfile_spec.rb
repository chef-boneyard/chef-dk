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
require 'shared/a_file_generator'
require 'chef-dk/command/generator_commands/policyfile'

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

  context "when ARGV has too many arguments" do

    let(:argv) { %w{ foo bar baz } }

    it "shows usage and exits" do
      expected_stdout = "Usage: chef generate policyfile [NAME] [options]"

      expect(generator.run).to eq(1)
      expect(stderr).to include(expected_stdout)
    end

  end

end


