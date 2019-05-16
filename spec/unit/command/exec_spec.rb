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
require "chef-dk/command/exec"

describe ChefDK::Command::Exec do
  let(:command_instance) { ChefDK::Command::Exec.new() }

  let(:command_options) { [] }

  def run_command
    command_instance.run_with_default_options(false, command_options)
  end

  it "has a usage banner" do
    expect(command_instance.banner).to eq("Usage: chef exec SYSTEM_COMMAND")
  end

  describe "when locating omnibus directory" do
    it "should find omnibus bin directory from ruby path" do
      allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby"))
      expect(command_instance.omnibus_bin_dir).to include("eg_omnibus_dir/valid/bin")
    end

    it "should find omnibus embedded bin directory from ruby path" do
      allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby"))
      expect(command_instance.omnibus_embedded_bin_dir).to include("eg_omnibus_dir/valid/embedded/bin")
    end

    it "should raise OmnibusInstallNotFound if directory is not looking like omnibus" do
      allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, ".rbenv/versions/2.1.1/bin/ruby"))
      expect { command_instance.omnibus_bin_dir }.to raise_error(ChefDK::OmnibusInstallNotFound)
    end

    it "should raise OmnibusInstallNotFound if directory is not looking like omnibus" do
      allow(Gem).to receive(:ruby).and_return(File.join(fixtures_path, ".rbenv/versions/2.1.1/bin/ruby"))
      expect { command_instance.omnibus_embedded_bin_dir }.to raise_error(ChefDK::OmnibusInstallNotFound)
    end
  end

  describe "when running exec command" do
    let(:ruby_path) { File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby") }

    before do
      allow(Gem).to receive(:ruby).and_return(ruby_path)

      # Using a fake path separator to keep to prevent people from accidently
      # getting things correct on their system. This enforces that, in general,
      # you should use the path separator ruby is telling you to use.
      stub_const("File::PATH_SEPARATOR", "<>")
    end

    context "when running exec env" do
      let(:command_options) { %w{gem list} }

      let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, "bin")) }

      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:omnibus_bin_dir) { "/foo/bin" }

      let(:expected_PATH) { [omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"]].join(File::PATH_SEPARATOR) }

      let(:expected_GEM_ROOT) { Gem.default_dir }

      let(:expected_GEM_HOME) { Gem.user_dir }

      let(:expected_GEM_PATH) { Gem.path.join(File::PATH_SEPARATOR) }

      before do
        allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
        allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      end

      it "should call exec to fire off the command with the correct environment" do
        expect(ENV).to receive(:[]=).with("PATH", expected_PATH)
        expect(ENV).to receive(:[]=).with("GEM_ROOT", expected_GEM_ROOT)
        expect(ENV).to receive(:[]=).with("GEM_HOME", expected_GEM_HOME)
        expect(ENV).to receive(:[]=).with("GEM_PATH", expected_GEM_PATH)

        expect(command_instance).to receive(:exec).with(*command_options)
        expect { run_command }.to raise_error(RuntimeError) # XXX: this isn't a test we just need to swallow the exception
      end

      ["-v", "--version", "-h", "--help"].each do |switch|
        context "when running a command with #{switch}" do
          let(:command_options) { %W{gem list #{switch}} }

          it "should call exec to fire off the command with the correct environment" do
            expect(ENV).to receive(:[]=).with("PATH", expected_PATH)
            expect(ENV).to receive(:[]=).with("GEM_ROOT", expected_GEM_ROOT)
            expect(ENV).to receive(:[]=).with("GEM_HOME", expected_GEM_HOME)
            expect(ENV).to receive(:[]=).with("GEM_PATH", expected_GEM_PATH)

            expect(command_instance).to receive(:exec).with(*command_options)
            expect { run_command }.to raise_error(RuntimeError) # XXX: this isn't a test we just need to swallow the exception
          end
        end
      end

      ["-h", "--help"].each do |switch|
        context "when running a exec with #{switch} and things after it" do
          let(:command_options) { %W{#{switch} gem} }

          it "should call not call exec, but it should print the banner" do
            allow(command_instance).to receive(:msg)
            expect(ENV).not_to receive(:[]=)
            expect(command_instance).to receive(:banner)
            expect(command_instance).not_to receive(:exec)
            run_command
          end
        end

        context "when running a exec with #{switch}" do
          let(:command_options) { ["#{switch}"] }

          it "should call not call exec, but it should print the banner" do
            allow(command_instance).to receive(:msg)
            expect(ENV).not_to receive(:[]=)
            expect(command_instance).to receive(:banner)
            expect(command_instance).not_to receive(:exec)
            run_command
          end
        end
      end
    end

    context "when running command that does not exist" do
      let(:command_options) { %w{chef_rules_everything_aroundme} }

      let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, "bin")) }

      let(:omnibus_bin_dir) { "/foo/bin" }

      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:expected_PATH) { [omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"]].join(File::PATH_SEPARATOR) }

      let(:expected_GEM_ROOT) { Gem.default_dir }

      let(:expected_GEM_HOME) { Gem.user_dir }

      let(:expected_GEM_PATH) { Gem.path.join(File::PATH_SEPARATOR) }

      before do
        allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
        allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      end

      it "should raise Errno::ENOENT" do
        expect(ENV).to receive(:[]=).with("PATH", expected_PATH)
        expect(ENV).to receive(:[]=).with("GEM_ROOT", expected_GEM_ROOT)
        expect(ENV).to receive(:[]=).with("GEM_HOME", expected_GEM_HOME)
        expect(ENV).to receive(:[]=).with("GEM_PATH", expected_GEM_PATH)

        # XXX: this doesn't really test much, but really calling exec will never return to rspec
        expect(command_instance).to receive(:exec).with(*command_options).and_raise(Errno::ENOENT)
        expect { run_command }.to raise_error(Errno::ENOENT)
      end
    end
  end

end
