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

require_relative "bundle"
require_relative "version"
require_relative "dependencies"

desc "Tasks intended to be called by ci automation"
namespace :ci do
  desc "Calls Bump and includes an install of the version of bundler specified in omnibus_overrides"
  task :version_bump => %w{version:bump_patch bundle:install_bundler bundle:install}

  desc "Show the current version."
  task :version_show => %w{version:show}

  desc "Update all dependencies and includes an update to bundler."
  task :dependencies => %w{
                    dependencies:update_stable_channel_gems
                    dependencies:update_gemfile_lock
                    dependencies:update_omnibus_overrides
                    bundle:install_bundler
                    dependencies:update_omnibus_gemfile_lock
                    dependencies:update_acceptance_gemfile_lock
                    bundle:outdated
                  }
end
