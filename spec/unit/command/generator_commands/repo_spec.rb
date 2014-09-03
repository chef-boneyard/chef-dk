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
require 'shared/a_generated_file'
require 'chef-dk/command/generator_commands/repo'

describe ChefDK::Command::GeneratorCommands::Repo do

  let(:argv) { %w[new_repo] }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w[
      LICENSE
    ]
  end

  let(:file) { "" }
  let(:file_path) { File.join(repo_path, file) }
  let(:file_contents) { File.read(file_path) }
  let(:repo_path) { File.join(tempdir, "new_repo") }

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "new_repo", relpath)
    end
  end

  subject(:generator) { described_class.new(argv) }

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
  end

  context "when given the name of the repo to generate" do

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      generator.read_and_validate_params
      generator.setup_context
      expect(generator_context.repo_root).to eq(Dir.pwd)
      expect(generator_context.repo_name).to eq("new_repo")
    end

    it "creates a new repo" do
      Dir.chdir(tempdir) do
        allow(generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        generator.run
      end
      generated_files = Dir.glob(File.join(tempdir, "new_repo", "**", "*"), File::FNM_DOTMATCH)
      expected_cookbook_files.each do |expected_file|
        expect(generated_files).to include(expected_file)
      end
    end

    describe "generated files" do
      before do
        Dir.chdir(tempdir) do
          allow(generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          generator.run
        end
      end

      describe "LICENSE" do
        let(:file) { "LICENSE" }

        context "all_rights" do
          it "is the default" do
            expect(file_contents).to match(/Copyright \d\d\d\d/)
            expect(file_contents).to match(/All rights reserved, do not redistribute/)
          end

          context "with copyright_holder" do
            let(:argv) { ["new_repo", "-C", "Adam Jacob"] }
            it "includes the name" do
              expect(file_contents).to match(/Copyright \d\d\d\d Adam Jacob/)
            end
          end
        end

        context "apache2" do
          let(:argv) { ["new_repo", "-I", "apache2" ] }

          it "is the apache license" do
            expect(file_contents).to match(/Apache License/)
            expect(file_contents).to match(/Version 2.0/)
          end
        end

        context "mit" do
          let(:argv) { ["new_repo", "-I", "mit" ] }

          it "is the mit license" do
            expect(file_contents).to match(/The MIT License \(MIT\)/)
          end

          context "with copyright_holder" do
            let(:argv) { ["new_repo", "-I", "mit", "-C", "Adam Jacob"] }
            it "includes the name" do
              expect(file_contents).to match(/Copyright \(c\) \d\d\d\d Adam Jacob/)
            end
          end
        end

        context "gplv2" do
          let(:argv) { ["new_repo", "-I", "gplv2" ] }

          it "is the GPL version 2 license" do
            expect(file_contents).to match(/GNU GENERAL PUBLIC LICENSE/)
            expect(file_contents).to match(/Version 2, June 1991/)
          end
        end

        context "gplv3" do
          let(:argv) { ["new_repo", "-I", "gplv3" ] }

          it "is the GPL version 2 license" do
            expect(file_contents).to match(/GNU GENERAL PUBLIC LICENSE/)
            expect(file_contents).to match(/Version 3, 29 June 2007/)
          end
        end
      end

      describe "README.md" do
        let(:file) { "README.md" }

        it "is the standard readme" do
          expect(file_contents).to match(/Every Chef installation needs a Chef Repository/)
        end
      end

      describe "chefignore" do
        let(:file) { "chefignore" }

        it "has the preamble" do
          expect(file_contents).to match(/Put files\/directories that should be ignored in this file when uploading/)
        end
      end

      describe ".gitignore" do
        let(:file) { ".gitignore" }

        it "has the right contents" do
          expect(file_contents).to match(/\.rake_test_cache/)
          expect(file_contents).to match(/\.chef\/\*\.pem/)
          expect(file_contents).to match(/\.chef\/encrypted_data_bag_secret/)
          expect(file_contents).to_not match(/cookbooks\/\*\*/)
        end

        context "with --policy-only" do
          let(:argv) { ["new_repo", "--policy-only" ] }

          it "blocks cookbooks" do
            expect(file_contents).to match(/cookbooks\/\*\*/)
            expect(file_contents).to match(/cookbooks\/README\.md/)
          end
        end
      end

      describe "cookbooks" do
        describe "README.md" do
          let(:file) { "cookbooks/README.md" }

          it "has the right contents" do
            expect(file_contents).to match(/This directory contains the cookbooks/)
          end

          context "with --policy-only" do
            let(:argv) { ["new_repo", "--policy-only" ] }

            it "tells you whats up" do
              expect(file_contents).to match(/This directory typically contains Chef cookbooks/)
            end
          end
        end

        describe "example/metadata.rb" do
          let(:file) { "cookbooks/example/metadata.rb" }

          it "has the right contents" do
            expect(file_contents).to match(/name 'example'/)
          end
        end

        describe "example/attributes/default.rb" do
          let(:file) { "cookbooks/example/attributes/default.rb" }

          it "has the right contents" do
            expect(file_contents).to match(/default\["example"\]\["name"\] = "Sam Doe"/)
          end
        end

        describe "example/recipes/default.rb" do
          let(:file) { "cookbooks/example/recipes/default.rb" }

          it "has the right contents" do
            expect(file_contents).to match(/log "Welcome to Chef, \#\{node\["example"\]\["name"\]\}!" do/)
          end
        end
      end

      describe "data_bags" do
        describe "README.md" do
          let(:file) { "data_bags/README.md" }

          it "has the right contents" do
            expect(file_contents).to match(/This directory contains directories of the various data bags/)
          end
        end

        describe "example_item.json" do
          let(:file) { "data_bags/example/example_item.json" }

          it "has the right contents" do
            expect(file_contents).to match(/"id": "example_item"/)
          end
        end
      end

      describe "environments" do
        describe "README.md" do
          let(:file) { "environments/README.md" }

          it "has the right contents" do
            expect(file_contents).to match(/Create environments here, in either the Role Ruby DSL \(\.rb\) or JSON \(\.json\) files\./)
          end
        end

        describe "example.json" do
          let(:file) { "environments/example.json" }

          it "has the right contents" do
            expect(file_contents).to match(/"description": "This is an example environment defined as JSON"/)
          end
        end
      end

      describe "roles" do
        describe "README.md" do
          let(:file) { "roles/README.md" }

          it "has the right contents" do
            expect(file_contents).to match(/Create roles here, in either the Role Ruby DSL \(\.rb\) or JSON \(\.json\) files\./)
          end
        end

        describe "example.json" do
          let(:file) { "roles/example.json" }

          it "has the right contents" do
            expect(file_contents).to match(/"description": "This is an example role defined as JSON"/)
          end
        end
      end
    end
  end
end


