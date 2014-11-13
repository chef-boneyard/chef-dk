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
require 'chef-dk/command/shell_init'

describe ChefDK::Command::ShellInit do

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:command_instance) do
    ChefDK::Command::ShellInit.new.tap do |c|
      allow(c).to receive(:stdout).and_return(stdout_io)
      allow(c).to receive(:stderr).and_return(stderr_io)
    end
  end

  before do
    stub_const("File::PATH_SEPARATOR", ':')
  end

  let(:argv) { ['bash'] }

  let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, 'bin')) }

  let(:expected_path) { [omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV['PATH']].join(File::PATH_SEPARATOR) }

  let(:expected_gem_root) { Gem.default_dir.to_s }

  let(:expected_gem_home) { Gem.user_dir }

  let(:expected_gem_path) { Gem.path.join(':') }

  let(:expected_environment_commands) do
    <<-EOH
export PATH=#{expected_path}
export GEM_ROOT="#{expected_gem_root}"
export GEM_HOME=#{expected_gem_home}
export GEM_PATH=#{expected_gem_path}
EOH
  end

  context "with no explicit omnibus directory" do

    let(:omnibus_bin_dir) { "/foo/bin" }
    let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

    before do
      allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
      allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
    end

    it "emits a script to add ChefDK's ruby to the shell environment" do
      command_instance.run(argv)
      expect(stdout_io.string).to eq(expected_environment_commands)
    end

    context "when no shell is specified" do

      let(:argv) { [] }

      it "exits with an error message" do
        expect(command_instance.run(argv)).to eq(1)
        expect(stderr_io.string).to include("Please specify what shell you are using")
      end

    end

    context "when an unsupported shell is specified" do

      let(:argv) { ['nosuchsh'] }

      it "exits with an error message" do
        expect(command_instance.run(argv)).to eq(1)
        expect(stderr_io.string).to include("Shell `nosuchsh' is not currently supported")
        expect(stderr_io.string).to include("Supported shells are: bash zsh sh")
      end

    end

  end

  context "with an explicit omnibus directory as an argument" do

    let(:omnibus_root) { File.join(fixtures_path, "eg_omnibus_dir/valid/") }
    let(:omnibus_bin_dir) { File.join(omnibus_root, "bin") }
    let(:omnibus_embedded_bin_dir) { File.join(omnibus_root, "embedded/bin") }

    let(:argv) { ["bash", "--omnibus-dir", omnibus_root] }

    it "emits a script to add ChefDK's ruby to the shell environment" do
      command_instance.run(argv)
      expect(stdout_io.string).to eq(expected_environment_commands)
    end
  end

end

