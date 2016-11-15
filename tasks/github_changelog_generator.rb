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

  namespace :changelog do
    # Take the current changelog and move it to HISTORY.md. Removes lines that
    # would get duplicated the next time we pull HISTORY into the CHANGELOG.
    task :archive do
      changelog = File.readlines("CHANGELOG.md")
      File.open("HISTORY.md", "w+") { |f| f.write(changelog[2..-4].join("")) }
    end

    # Run this to just update the changelog for the current release. This will
    # take what is in History and generate a changelog of PRs between the most
    # recent tag in HISTORY.md and HEAD.
    GitHubChangelogGenerator::RakeTask.new :update do |config|
      config.since_tag = "v0.19.6"
      config.between_tags = []
      config.future_release = "v1.0.3"
      config.max_issues = 0
      config.add_issues_wo_labels = false
      config.enhancement_labels = "enhancement,Enhancement,New Feature,Feature".split(",")
      config.bug_labels = "bug,Bug,Improvement,Upstream Bug".split(",")
      config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog,Exclude From Changelog,Question,Discussion".split(",")
    end
  end

  task :changelog => "changelog:update"
rescue LoadError
  puts "github_changelog_generator is not available. gem install github_changelog_generator to generate changelogs"
end
