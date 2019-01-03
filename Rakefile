#
# Copyright:: Copyright (c) 2016-2018 Chef Software Inc.
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
  require_relative "tasks/dependencies"
  require_relative "tasks/announce"
rescue LoadError
  puts "Additional rake tasks not found. If you require these rake tasks run Rake from the git repo not the installation files!"
end

namespace :style do
  begin
    require "rubocop/rake_task"

    desc "Run Cookbook Ruby style checks"
    RuboCop::RakeTask.new(:cookstyle) do |t|
      t.requires = ["cookstyle"]
      t.patterns = ["lib/chef-dk/skeletons/code_generator"]
      t.options = ["--display-cop-names"]
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV["CI"]
  end

  begin
    require "rubocop/rake_task"

    ignore_dirs = Regexp.union(%w{
      lib/chef-dk/skeletons/code_generator
      spec/unit/fixtures/chef-runner-cookbooks
      spec/unit/fixtures/cookbook_cache
      spec/unit/fixtures/example_cookbook
      spec/unit/fixtures/example_cookbook_metadata_json_only
      spec/unit/fixtures/example_cookbook_no_metadata
      spec/unit/fixtures/local_path_cookbooks
    })

    desc "Run Chef Ruby style checks"
    RuboCop::RakeTask.new(:chefstyle) do |t|
      t.requires = ["chefstyle"]
      t.patterns = `rubocop --list-target-files`.split("\n").reject { |f| f =~ ignore_dirs }
      t.options = ["--display-cop-names"]
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV["CI"]
  end

  begin
    require "foodcritic"

    desc "Run Chef Cookbook (Foodcritic) style checks"
    FoodCritic::Rake::LintTask.new(:foodcritic) do |t|
      t.options = {
        fail_tags: ["any"],
        tags: ["~FC071", "~supermarket", "~FC031"],
        cookbook_paths: ["lib/chef-dk/skeletons/code_generator"],
        progress: true,
      }
    end
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting #{task.name}" unless ENV["CI"]
  end
end
