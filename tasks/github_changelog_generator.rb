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

begin
  require "github_changelog_generator/task"
  require "mixlib/install"

  namespace :changelog do
    # Fetch the latest version from mixlib-install
    latest_stable_version = Mixlib::Install.available_versions("chefdk", "stable").last

    # Take the changelog from the latest stable release and put it into history.
    desc "Archive current CHANGELOG to HISTORY"
    task :archive do
      changelog = Net::HTTP.get(URI("https://raw.githubusercontent.com/chef/chef-dk/v#{latest_stable_version}/CHANGELOG.md")).chomp.split("\n")
      File.open("HISTORY.md", "w+") { |f| f.write(changelog[2..-4].join("\n")) }
    end

    # Run this to just update the changelog for the current release. This will
    # take what is in HISTORY and generate a changelog of PRs between the most
    # recent stable version and HEAD.
    GitHubChangelogGenerator::RakeTask.new :update do |config|
      config.future_release = "v#{ChefDK::VERSION}"
      config.between_tags = ["v#{latest_stable_version}", "v#{ChefDK::VERSION}"]
      config.max_issues = 0
      config.add_issues_wo_labels = false
      config.enhancement_labels = "enhancement,Enhancement,New Feature,Feature".split(",")
      config.bug_labels = "bug,Bug,Improvement,Upstream Bug".split(",")
      config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog,Exclude From Changelog,Question,Discussion".split(",")
      config.header = "This changelog reflects the current state of chef-dk's master branch on github and may not reflect the current released version of chef-dk, which is [![Gem Version](https://badge.fury.io/rb/chef-dk.svg)](https://badge.fury.io/rb/chef-dk)."
    end
  end

  task :changelog => "changelog:update"
rescue LoadError
  puts "github_changelog_generator is not available. gem install github_changelog_generator to generate changelogs"
end
