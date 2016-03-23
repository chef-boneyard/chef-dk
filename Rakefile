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

require "bundler/gem_tasks"

require "github_changelog_generator/task"

namespace :version do
  task :bump => 'version:bump_patch'

  task :show do
    puts ChefDK::VERSION
  end

  def version_rb_path
    File.expand_path("../lib/chef-dk/version.rb", __FILE__)
  end

  # Add 1 to the current patch version in the VERSION file, and write it back out.
  task :bump_patch do
    current_version_file = IO.read(version_rb_path)
    new_version = nil
    new_version_file = current_version_file.sub(/^(\s*VERSION\s*=\s*")(\d+\.\d+\.)(\d+)/) do
      new_version = "#{$2}#{$3.to_i + 1}"
      "#{$1}#{new_version}"
    end
    puts "Updating version in #{version_rb_path} from #{ChefDK::VERSION} to #{new_version.chomp}"
    IO.write(version_rb_path, new_version_file)
  end

end

require_relative 'tasks/dependencies'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = "chef"
  config.project = "chef-dk"
  config.future_release = ChefDK::VERSION
  config.enhancement_labels = "enhancement,Enhancement,New Feature,Feature".split(",")
  config.bug_labels = "bug,Bug,Improvement,Upstream Bug".split(",")
  config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog,Exclude From Changelog,Question,Discussion".split(",")
end
