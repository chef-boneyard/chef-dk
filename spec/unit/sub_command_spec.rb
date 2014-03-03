3#
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
require 'chef-dk/sub_command'
require 'stringio'

describe ChefDK::SubCommand do
  class Log
    def self.log
      @log ||= StringIO.new
    end

    def self.reset
      @log = nil
    end
  end

  before(:each) do
    Log.reset
  end

  class TestSubCommand
    def run(params)
      Log.log.puts "rolled: #{params[0]}"
    end
  end

  class TestClass
   include ChefDK::SubCommand

    sub_command "roll", TestSubCommand
  end

  let(:test_instance) { TestClass.new }

  describe "when a class is using sub_class" do
    it "subcommands should be a Hash" do
      expect(test_instance.sub_commands).to be_instance_of(Hash)
    end

    it "subcommands should include the specified sub_command" do
      expect(test_instance.sub_commands.keys).to include("roll")
    end

    it "run_sub_commands should not fail when called with empty parameters" do
      expect(test_instance.run_sub_commands(nil)).to be_false
      expect{test_instance.run_sub_commands(nil)}.not_to raise_error
      expect(test_instance.run_sub_commands([ ])).to be_false
      expect{test_instance.run_sub_commands([ ])}.not_to raise_error
    end

    it "run_sub_commands should run the command and return true with a valid command" do
      expect(test_instance.run_sub_commands([ "roll", "dice"])).to be_true
      expect(Log.log.string.chomp).to eq("rolled: dice")
    end

    it "run_sub_commands should not run the command and return false when called with parameters" do
      expect(test_instance.run_sub_commands([ "-h" ])).to be_false
      expect(Log.log.string.chomp).to eq("")
    end
  end
end
