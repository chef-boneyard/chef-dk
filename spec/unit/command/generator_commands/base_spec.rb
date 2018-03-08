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

require "pry"
require "spec_helper"
require "chef-dk/command/generator_commands/base"

describe ChefDK::Command::GeneratorCommands::Base do
  describe "parsing Chef configuration" do
    let(:cli_args) do
      [
        "-C", "Business Man",
        "-I", "Serious Business",
        "-m", "business.man@corporation.com"
      ]
    end

    before do
      Chef::Config.reset
    end

    context "when generator configuration is defined" do
      before do
        Chef::Config.reset
        Chef::Config.chefdk.generator.copyright_holder = "This Guy"
        Chef::Config.chefdk.generator.email = "this.guy@twothumbs.net"
        Chef::Config.chefdk.generator.license = "Two Thumbs License"
      end

      it "uses the defined values" do
        cmd = ChefDK::Command::GeneratorCommands::Base.new([])
        cmd.parse_options
        cmd.setup_context
        cfg = cmd.config
        expect(cfg[:copyright_holder]).to eq("This Guy")
        expect(cfg[:email]).to eq("this.guy@twothumbs.net")
        expect(cfg[:license]).to eq("Two Thumbs License")
      end

      context "when cli overrides are provided" do
        before do
          Chef::Config.reset
          Chef::Config.chefdk.generator.copyright_holder = "This Guy"
          Chef::Config.chefdk.generator.email = "this.guy@twothumbs.net"
          Chef::Config.chefdk.generator.license = "Two Thumbs License"
        end

        it "uses the cli args" do
          cmd = ChefDK::Command::GeneratorCommands::Base.new(cli_args)
          cmd.parse_options(cli_args)
          cmd.setup_context
          cfg = cmd.config
          expect(cfg[:copyright_holder]).to eq("Business Man")
          expect(cfg[:email]).to eq("business.man@corporation.com")
          expect(cfg[:license]).to eq("Serious Business")
        end
      end

      context "when knife configuration is also defined" do

        before do
          Chef::Config.reset
          Chef::Config.chefdk.generator.copyright_holder = "This Guy"
          Chef::Config.chefdk.generator.email = "this.guy@twothumbs.net"
          Chef::Config.chefdk.generator.license = "Two Thumbs License"
          Chef::Config.knife.cookbook_copyright = "Knife User"
          Chef::Config.knife.cookbook_email = "knife.user@example.com"
          Chef::Config.knife.cookbook_license = "GPLv9000"
        end

        it "uses the generator configuration" do
          cmd = ChefDK::Command::GeneratorCommands::Base.new([])
          cmd.parse_options
          cmd.setup_context
          cfg = cmd.config
          expect(cfg[:copyright_holder]).to eq("This Guy")
          expect(cfg[:email]).to eq("this.guy@twothumbs.net")
          expect(cfg[:license]).to eq("Two Thumbs License")
        end
      end
    end

    context "when knife configuration is defined" do
      before do
        Chef::Config.reset
        Chef::Config.knife.cookbook_copyright = "Knife User"
        Chef::Config.knife.cookbook_email = "knife.user@example.com"
        Chef::Config.knife.cookbook_license = "GPLv9000"
      end

      it "uses the defined values" do
        cmd = ChefDK::Command::GeneratorCommands::Base.new([])
        cmd.parse_options
        cmd.setup_context
        cfg = cmd.config
        expect(cfg[:copyright_holder]).to eq("Knife User")
        expect(cfg[:email]).to eq("knife.user@example.com")
        expect(cfg[:license]).to eq("GPLv9000")
      end

      context "when cli overrides are provided" do

        before do
          Chef::Config.reset
          Chef::Config.knife.cookbook_copyright = "Knife User"
          Chef::Config.knife.cookbook_email = "knife.user@example.com"
          Chef::Config.knife.cookbook_license = "GPLv9000"
        end

        it "uses the cli args" do
          cmd = ChefDK::Command::GeneratorCommands::Base.new(cli_args)
          cmd.parse_options(cli_args)
          cmd.setup_context
          cfg = cmd.config
          expect(cfg[:copyright_holder]).to eq("Business Man")
          expect(cfg[:email]).to eq("business.man@corporation.com")
          expect(cfg[:license]).to eq("Serious Business")
        end
      end
    end
  end

  describe "#have_git?" do
    let(:cmd) { described_class.new([]) }
    let(:path) { "bin_path" }

    before do
      allow(File).to receive(:exist?)
      allow(ENV).to receive(:[]).with("PATH").and_return(path)
      allow(ENV).to receive(:[]).with("PATHEXT").and_return(nil)
      allow(RbConfig::CONFIG).to receive(:[]).with("EXEEXT").and_return("")
    end

    describe "when git executable exists" do
      it "returns true" do
        allow(File).to receive(:exist?).and_return(true)
        expect(cmd.have_git?).to eq(true)
      end
    end

    describe "when git executable does not exist" do
      it "returns false" do
        allow(File).to receive(:exist?).and_return(false)
        expect(cmd.have_git?).to eq(false)
      end
    end

    it "checks PATH for git executable" do
      expect(File).to receive(:exist?).with(File.join(path, "git"))
      cmd.have_git?
    end

    describe "when on Windows" do
      before do
        allow(ENV).to receive(:[]).with("PATHEXT").and_return(".com;.exe;.bat")
        allow(RbConfig::CONFIG).to receive(:[]).with("EXEEXT").and_return(".exe")
      end

      it "checks PATH for git executable with an extension found in PATHEXT" do
        expect(File).to receive(:exist?).with(File.join(path, "git.com"))
        expect(File).to receive(:exist?).with(File.join(path, "git.exe"))
        expect(File).to receive(:exist?).with(File.join(path, "git.bat"))
        cmd.have_git?
      end
    end
  end
end
