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

require 'mixlib/cli'
require 'chef-dk/version'
require 'chef-dk/sub_command'
require 'chef-dk/command/verify'
require 'chef-dk/command/gem'

module ChefDK
  class CLI
    include Mixlib::CLI
    include ChefDK::SubCommand

    option :version,
      :short        => "-v",
      :long         => "--version",
      :description  => "Show chef version",
      :boolean      => true,
      :proc         => lambda {|v| puts "Chef Development Kit Version: #{ChefDK::VERSION}"},
      :exit         => 0

    option :help,
      :short        => "-h",
      :long         => "--help",
      :description  => "Show this message",
      :boolean      => true,
      :proc         => lambda {|v| puts "Available commands are: #{sub_commands.keys.join(", ")}"},
      :exit         => 0

    sub_command "verify", ChefDK::Command::Verify
    sub_command "gem", ChefDK::Command::GemForwarder

    def initialize
      super
    end

    def run
      run_sub_commands(ARGV) || parse_options
    end

  end
end
