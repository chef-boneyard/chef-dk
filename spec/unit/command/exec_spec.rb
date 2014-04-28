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
require 'chef-dk/command/exec'

describe ChefDK::Command::Exec do
  let(:command_instance) { ChefDK::Command::Exec.new() }

  let(:command_options) { [] }

  def run_command
    command_instance.run(command_options)
  end

  it "has a usage banner" do
    expect(command_instance.banner).to eq("Usage: chef exec SYSTEM_COMMAND")
  end

  describe "when locating omnibus directory" do
    it "should find omnibus bin directory from ruby path" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby"))
      expect(command_instance.omnibus_bin_dir).to include("eg_omnibus_dir/valid/bin")
    end

    it "should find omnibus embedded bin directory from ruby path" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby"))
      expect(command_instance.omnibus_embedded_bin_dir).to include("eg_omnibus_dir/valid/embedded/bin")
    end

    it "should raise OmnibusInstallNotFound if directory is not looking like omnibus" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path,".rbenv/versions/2.1.1/bin/ruby"))
      expect{command_instance.omnibus_bin_dir}.to raise_error(ChefDK::Exceptions::OmnibusInstallNotFound)
    end

    it "should raise OmnibusInstallNotFound if directory is not looking like omnibus" do
      Gem.stub(:ruby).and_return(File.join(fixtures_path,".rbenv/versions/2.1.1/bin/ruby"))
      expect{command_instance.omnibus_embedded_bin_dir}.to raise_error(ChefDK::Exceptions::OmnibusInstallNotFound)
    end
  end

  describe "when running exec command" do
    let(:ruby_path) { File.join(fixtures_path, "eg_omnibus_dir/valid/embedded/bin/ruby") }

    before do
      Gem.stub(:ruby).and_return(ruby_path)
    end

    context "when running exec env" do
      let(:command_options) { %w{gem list} }

      let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, 'bin')) }

      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:expected_env) do
        {
          'PATH' => "#{user_bin_dir}:#{omnibus_embedded_bin_dir}:#{ENV['PATH']}",
          'GEM_ROOT' => Gem.default_dir.inspect,
          'GEM_HOME' => ENV['GEM_HOME'],
          'GEM_PATH' => Gem.path.join(':'),
        }
      end

      before do
        command_instance.stub(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
      end

      it "should call exec to fire off the command with the correct environment" do
        expect(command_instance).to receive(:exec).with(expected_env, *command_options)
        expect{ run_command }.to raise_error # XXX: this isn't a test we just need to swallow the exception
      end
    end

    context "when running command that does not exist" do
      let(:command_options) { %w{chef_rules_everything_aroundme} }

      let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, 'bin')) }

      let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }

      let(:expected_env) do
        {
          'PATH' => "#{user_bin_dir}:#{omnibus_embedded_bin_dir}:#{ENV['PATH']}",
          'GEM_ROOT' => Gem.default_dir.inspect,
          'GEM_HOME' => ENV['GEM_HOME'],
          'GEM_PATH' => Gem.path.join(':'),
        }
      end

      before do
        command_instance.stub(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
      end

      it "should raise Errno::ENOENT" do
        # XXX: this doesn't really test much, but really calling exec will never return to rspec
        expect(command_instance).to receive(:exec).with(expected_env, *command_options).and_raise(Errno::ENOENT)
        expect{ run_command }.to raise_error(Errno::ENOENT)
      end
    end
  end

end
