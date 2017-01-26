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

require "bundler/gem_tasks"
require_relative "tasks/version"
require_relative "tasks/bundle"
require_relative "tasks/dependencies"
require_relative "tasks/github_changelog_generator"
require_relative "tasks/announce"

desc "Keep the Dockerfile up-to-date"
task :update_dockerfile do
  require "mixlib/install"
  latest_stable_version = Mixlib::Install.available_versions("chefdk", "stable").last
  text = File.read("Dockerfile")
  new_text = text.gsub(/^ARG VERSION=[\d\.]+$/, "ARG VERSION=#{latest_stable_version}")
  File.open("Dockerfile", "w+") { |f| f.write(new_text) }
end
