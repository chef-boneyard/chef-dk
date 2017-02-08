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
require "chef-dk/pager"

describe ChefDK::Pager do

  context "with default options" do

    subject(:pager) { ChefDK::Pager.new }

    it "gives ENV for env" do
      expect(pager.env).to eq(ENV)
    end

    it "checks stdout for TTY" do
      expect($stdout).to receive(:tty?).twice.and_call_original
      expect(pager.have_tty?).to eq($stdout.tty?)
    end

    it "enables paging" do
      expect(pager).to receive(:env).and_return({ "PAGER" => "less" })
      expect(pager).to receive(:have_tty?).and_return(true)
      expect(pager.pager_enabled?).to be(true)
    end
  end

  context "with paging enabled" do

    subject(:pager) do
      ChefDK::Pager.new(enable_pager: true).tap do |p|
        allow(p).to receive(:env).and_return({ "PAGER" => "less" })
        allow(p).to receive(:have_tty?).and_return(true)
      end
    end

    let(:pipe_read) { instance_double("IO") }
    let(:pipe_write) { instance_double("IO") }

    let(:pager_env) { { "LESS" => "-FRX", "LV" => "-c" } }

    before do
      allow(IO).to receive(:pipe).and_return([pipe_read, pipe_write])
    end

    it "provides a UI object with stdout set to a pipe" do
      expect(pager.ui.out_stream).to eq(pipe_write)
    end

    it "starts the pager" do
      expect(Kernel).to receive(:trap).with(:INT, "IGNORE")
      expect(Process).to receive(:spawn).with(pager_env, "less", in: pipe_read).and_return(12345)
      expect(pipe_read).to receive(:close)
      pager.start
    end

    it "waits for the pager to exit" do
      expect(Kernel).to receive(:trap).with(:INT, "IGNORE")
      expect(Process).to receive(:spawn).with(pager_env, "less", in: pipe_read).and_return(12345)
      expect(pipe_read).to receive(:close)
      pager.start

      expect(pipe_write).to receive(:close)
      expect(Process).to receive(:waitpid).with(12345)
      pager.wait
    end
  end

  context "with paging disabled" do

    subject(:pager) do
      ChefDK::Pager.new(enable_pager: false).tap do |p|
        allow(p).to receive(:env).and_return({ "PAGER" => "less" })
        allow(p).to receive(:have_tty?).and_return(true)
      end
    end

    before do
      expect(IO).to_not receive(:pipe)
    end

    it "provides a UI with stdout set to stdout" do
      expect(pager.ui.out_stream).to eq($stdout)
    end

    it "no-ops on pager start" do
      expect(Kernel).to_not receive(:trap)
      expect(Process).to_not receive(:spawn)
      pager.start
    end

    it "no-ops on pager wait" do
      expect(Kernel).to_not receive(:trap)
      expect(Process).to_not receive(:spawn)
      pager.start

      expect(Process).to_not receive(:waitpid)
      pager.wait
    end

  end
end
