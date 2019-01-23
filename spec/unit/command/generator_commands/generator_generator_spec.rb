#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "pathname"
require "chef-dk/command/generator_commands/generator_generator"

describe ChefDK::Command::GeneratorCommands::GeneratorGenerator do

  let(:argv) { raise "define let(:argv)" }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:repo_root) { File.expand_path("../../../../..", __FILE__) }

  let(:builtin_generator_path) { File.join(repo_root, "lib/chef-dk/skeletons/code_generator") }

  let(:builtin_generator_full_paths) { Dir["#{builtin_generator_path}/**/*"] }

  let(:expected_files_relpaths) do
    base = Pathname.new(builtin_generator_path)
    builtin_generator_full_paths.map { |p| Pathname.new(p).relative_path_from(base).to_s }
  end

  let(:ui) { TestHelpers::TestUI.new }

  subject(:generator_generator) { described_class.new(argv) }

  before do
    # This has to be the very first thing we do for any tests
    reset_tempdir

    generator_generator.ui = ui
    allow(generator_generator).to receive(:stdout).and_return(stdout_io)
    allow(generator_generator).to receive(:stderr).and_return(stdout_io)
  end

  def actual_files(base_path)
    Dir["#{base_path}/**/*"]
  end

  context "with no arguments" do

    let(:argv) { [] }

    let(:expected_files_full_paths) do
      expected_files_relpaths.map { |p| File.join(tempdir, "code_generator", p) }
    end

    it "creates a copy of code_generator in the CWD" do
      Dir.chdir(tempdir) do
        expect(generator_generator.run).to eq(0)
      end
      base_path = File.join(tempdir, "code_generator")
      expect(actual_files(base_path)).to match_array(expected_files_full_paths)
    end

    it "names the cookbook code_generator" do
      generator_generator.verify_params!
      expect(generator_generator.cookbook_name).to eq("code_generator")
    end

    context "when the generator cookbook is configured in the config file" do

      before do
        Chef::Config.chefdk.generator_cookbook("/foo/bar/baz")
      end

      it "copies the default generator" do
        expect(generator_generator.source).to eq(builtin_generator_path)
      end

    end

  end

  context "with a path argument" do

    context "when the path is a directory that exists" do

      let(:argv) { [ tempdir ] }

      context "and there is a directory named code_generator in that directory" do

        let(:conflicting_dir) { File.join(tempdir, "code_generator") }

        before do
          FileUtils.mkdir(conflicting_dir)
        end

        it "fails" do
          expect(generator_generator.run).to eq(1)
          expect(actual_files(tempdir)).to eq([ conflicting_dir ])

          expected_msg = "ERROR: file or directory #{conflicting_dir} exists.\n"

          expect(ui.output).to eq(expected_msg)
        end
      end

      context "and there isn't a directory named code_generator in that directory" do

        let(:expected_files_full_paths) do
          expected_files_relpaths.map { |p| File.join(tempdir, "code_generator", p) }
        end

        it "names the cookbook code_generator" do
          generator_generator.verify_params!
          expect(generator_generator.cookbook_name).to eq("code_generator")
        end

        it "copies the code_generator to GIVEN_DIR/code_generator" do
          expect(generator_generator.run).to eq(0)

          base_path = File.join(tempdir, "code_generator")
          expect(actual_files(base_path)).to match_array(expected_files_full_paths)
        end
      end

    end

    context "when the path is a regular file" do

      let(:conflicting_file) { File.join(tempdir, "roadblock") }

      let(:argv) { [ conflicting_file ] }

      before do
        FileUtils.touch(conflicting_file)
      end

      it "fails" do
        expect(generator_generator.run).to eq(1)
        expect(actual_files(tempdir)).to eq([ conflicting_file ])

        expected_msg = "ERROR: #{conflicting_file} exists and is not a directory.\n"

        expect(ui.output).to eq(expected_msg)
      end

    end

    context "when the last element of the given path doesn't exist" do

      let(:target_dir) { File.join(tempdir, "my_cool_generator") }

      let(:argv) { [ target_dir ] }

      let(:expected_files_full_paths) do
        expected_files_relpaths.map { |p| File.join(target_dir, p) }
      end

      it "copies the code_generator as GIVEN_DIR" do
        expect(generator_generator.run).to eq(0)
        expect(actual_files(target_dir)).to match_array(expected_files_full_paths)
      end

      it "names the cookbook after the directory" do
        generator_generator.verify_params!
        expect(generator_generator.cookbook_name).to eq("my_cool_generator")
      end

      it "updates the metadata.rb with the correct name" do
        generator_generator.run

        metadata_path = File.join(target_dir, "metadata.rb")
        metadata_content = IO.read(metadata_path)
        expected_metadata = <<~METADATA
          name             'my_cool_generator'
          description      'Custom code generator cookbook for use with ChefDK'
          long_description 'Custom code generator cookbook for use with ChefDK'
          version          '0.1.0'

        METADATA
        expect(metadata_content).to eq(expected_metadata)
      end
    end

    context "when several elements of the given path don't exist" do

      let(:target_dir) { File.join(tempdir, "too", "many", "extra", "dirs") }

      let(:argv) { [ target_dir ] }

      it "fails" do
        expect(generator_generator.run).to eq(1)
        expect(actual_files(tempdir)).to eq([ ])

        parent = File.dirname(target_dir)
        expected_msg = "ERROR: enclosing directory #{parent} does not exist.\n"

        expect(ui.output).to eq(expected_msg)
      end
    end
  end

  context "with too many arguments" do

    let(:argv) { %w{ one extra } }

    it "fails" do
      expect(generator_generator.run).to eq(1)
      expect(actual_files(tempdir)).to eq([ ])

      expected_msg = "ERROR: Too many arguments.\n"

      expect(ui.output).to include(expected_msg)

    end
  end

end
