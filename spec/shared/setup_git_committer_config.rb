#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

require "mixlib/shellout"

RSpec.shared_context("setup_git_committer_config") do

  def _have_git_config_key?(key)
    cmd = Mixlib::ShellOut.new("git config --global #{key}", returns: [0, 1])
    cmd.run_command
    cmd.error!
    cmd.status.success?
  end

  def _git_config(subcommand_args)
    cmd = Mixlib::ShellOut.new("git config --global #{subcommand_args}")
    cmd.run_command
    cmd.error!
    cmd
  end

  before(:all) do
    unless _have_git_config_key?("user.name")
      _git_config("user.name \"chefdk_rspec_user\"")
    end
    unless _have_git_config_key?("user.email")
      _git_config("user.email \"chefdk_rspec_user@example.com\"")
    end
  end

  after(:all) do
    if _git_config("user.name").stdout.include?("chefdk_rspec_user")
      _git_config("--unset user.name")
    end
    if _git_config("user.email").stdout.include?("chefdk_rspec_user")
      _git_config("--unset user.email")
    end
  end

end
