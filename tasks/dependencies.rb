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

namespace :dependencies do
  # Update all dependencies to the latest constraint-matching version
  task :update do
    require 'fileutils'
    # Create Gemfile.lock
    sh "bin/bundle-platform \"ruby\" lock --update --lockfile Gemfile.lock"
    # Install the locked versions so that we can continue to run things.
    sh "bundle install"
    # Create Gemfile.windows.lock
    sh "bin/bundle-platform \"ruby x86-mingw32\" lock --update --lockfile Gemfile.windows.lock"
  end
  # Just like update, but only updates the minimum dependencies it can
  task :update_conservative do
    # Create Gemfile.lock
    sh "bin/bundle-platform \"ruby\" lock --lockfile Gemfile.lock"
    # Install the locked versions so that we can continue to run things.
    sh "bundle install"
    # Create Gemfile.windows.lock
    sh "bin/bundle-platform \"ruby x86-mingw32\" lock --update --lockfile Gemfile.windows.lock"
  end
  task :check do
    sh "bundle outdated" do |ok,err|
      # Ignore bad exit; this is only informational
    end
  end
end
task :dependencies => [ "dependencies:update", "dependencies:check" ]
