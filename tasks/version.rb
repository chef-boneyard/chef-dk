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

task :ci_version_bump do
  begin
    require "rake"

    Rake::Task["version:bump_patch"].invoke
    Rake::Task["version:update_gemfile_lock"].invoke

    begin
      Rake::Task["changelog:update"].invoke
    rescue Exception => e
      puts "There was an error updating the CHANGELOG"
      puts e
    end

    begin
      Rake::Task["update_dockerfile"].invoke
    rescue Exception => e
      puts "There was an error updating the Dockerfile"
      puts e
    end
  end
end

namespace :version do
  desc "Bump patch version in lib/chef-dk/version.rb and update Gemfile*.lock conservatively to include the new version. If Gemfile has changed, this will update modified constraints as well."
  task :bump => "ci_version_bump"

  desc "Show the current version."
  task :show do
    puts version
  end

  def version
    if IO.read(version_rb_path) =~ /^\s*VERSION\s*=\s*"([^"]+)"\s*$/
      $1
    else
      raise "Could not read version from #{version_rb_path}. Contents:\n#{IO.read(version_rb_path)}"
    end
  end

  def version_rb_path
    File.expand_path("../../lib/chef-dk/version.rb", __FILE__)
  end

  def gemfile_lock_path
    File.expand_path("../../Gemfile.lock", __FILE__)
  end

  def release_notes_path
    File.expand_path("../../RELEASE_NOTES.md", __FILE__)
  end

  # Add 1 to the current patch version in the VERSION file, and write it back out.
  desc "Bump the patch version in lib/chef-dk/version.rb."
  task :bump_patch do
    current_version_file = IO.read(version_rb_path)
    new_version = nil
    new_version_file = current_version_file.sub(/^(\s*VERSION\s*=\s*")(\d+\.\d+\.)(\d+)/) do
      new_version = "#{$2}#{$3.to_i + 1}"
      "#{$1}#{new_version}"
    end
    puts "Updating version in #{version_rb_path} from #{version} to #{new_version.chomp}"
    IO.write(version_rb_path, new_version_file)
  end

  desc "Bump the minor version in lib/chef-dk/version.rb"
  task :bump_minor do
    current_version_file = IO.read(version_rb_path)
    new_version = nil
    new_version_file = current_version_file.sub(/^(\s*VERSION\s*=\s*")(\d+)\.(\d+)\.(\d+)/) do
      new_version = "#{$2}.#{$3.to_i + 1}.0"
      "#{$1}#{new_version}"
    end
    puts "Updating version in #{version_rb_path} from #{version} to #{new_version.chomp}"
    IO.write(version_rb_path, new_version_file)
    IO.write(release_notes_path, "# ChefDK #{$2}.#{$3.to_i + 1} Release Notes")
    Rake::Task["changelog::archive"].invoke
    Rake::Task["version:update_gemfile_lock"].invoke
    Rake::Task["bundle:install"].invoke
  end

  desc "Bump the major version in lib/chef-dk/version.rb"
  task :bump_major do
    current_version_file = IO.read(version_rb_path)
    new_version = nil
    new_version_file = current_version_file.sub(/^(\s*VERSION\s*=\s*")(\d+)\.(\d+)\.(\d+)/) do
      new_version = "#{$2.to_i + 1}.0.0"
      "#{$1}#{new_version}"
    end
    puts "Updating version in #{version_rb_path} from #{version} to #{new_version.chomp}"
    IO.write(version_rb_path, new_version_file)
    IO.write(release_notes_path, "# ChefDK #{$2.to_i + 1}.0 Release Notes")
    Rake::Task["changelog::archive"].invoke
    Rake::Task["version:update_gemfile_lock"].invoke
    Rake::Task["bundle:install"].invoke
  end

  desc "Update the Gemfile.lock to include the current chef-dk version"
  task :update_gemfile_lock do
    if File.exist?(gemfile_lock_path)
      puts "Updating #{gemfile_lock_path} to include version #{version} ..."
      contents = IO.read(gemfile_lock_path)
      contents.gsub!(/^\s*(chef-dk)\s*\((= )?\S+\)\s*$/) do |line|
        line.gsub(/\((= )?\d+(\.\d+)+/) { "(#{$1}#{version}" }
      end
      IO.write(gemfile_lock_path, contents)
    end
  end

end
